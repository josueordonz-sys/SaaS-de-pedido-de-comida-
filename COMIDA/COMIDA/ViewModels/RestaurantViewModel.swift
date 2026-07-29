import AudioToolbox
import Combine
import FirebaseFirestore
import Foundation
import SwiftUI
import UserNotifications

class RestaurantViewModel: ObservableObject {
    @Published var productos: [Producto] = []
    @Published var pedidosPendientes: [Pedido] = []
    @Published var historialPedidos: [Pedido] = []
    private var db = Firestore.firestore()
    private var lastPedidoCount = 0
    private var isFirstFetch = true

    // Cargar inventario en tiempo real
    func fetchInventario() {
        db.collection("productos").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else { return }
            self.productos = documents.compactMap { doc -> Producto? in
                let data = doc.data()
                let nombre = data["nombre"] as? String ?? ""
                let precio = data["precio"] as? Double ?? 0.0
                let categoria = data["categoria"] as? String ?? ""
                let cantidad = data["cantidad"] as? Int ?? 0
                let vinculadoCon = data["vinculadoCon"] as? String
                let cantidadADescontar = data["cantidadADescontar"] as? Int
                return Producto(
                    id: doc.documentID, nombre: nombre, precio: precio, categoria: categoria,
                    cantidad: cantidad, vinculadoCon: vinculadoCon,
                    cantidadADescontar: cantidadADescontar)
            }
        }
    }

    // Cargar pedidos pendientes
    func fetchPedidos() {
        db.collection("pedidos").whereField("entregado", isEqualTo: false).addSnapshotListener {
            querySnapshot, error in
            guard let documents = querySnapshot?.documents else { return }

            let nuevosPedidos = documents.compactMap { doc -> Pedido? in
                let data = doc.data()
                let cliente = data["cliente"] as? String ?? ""
                let items = data["items"] as? [String: Int] ?? [:]
                let entregado = data["entregado"] as? Bool ?? false
                let timestamp = data["fecha"] as? Timestamp
                let fecha = timestamp?.dateValue() ?? Date()

                return Pedido(
                    id: doc.documentID, cliente: cliente, items: items, fecha: fecha,
                    entregado: entregado)
            }.sorted(by: { $0.fecha < $1.fecha })

            if !self.isFirstFetch && nuevosPedidos.count > self.pedidosPendientes.count {
                self.notificarNuevoPedido()
            }

            self.pedidosPendientes = nuevosPedidos
            self.isFirstFetch = false
        }
    }

    // Cargar historial de pedidos
    func fetchHistorial() {
        db.collection("pedidos")
            .order(by: "fecha", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    if let error = error {
                        print("Error fetching historial: \(error.localizedDescription)")
                    }
                    return
                }

                self.historialPedidos = documents.compactMap { doc -> Pedido? in
                    let data = doc.data()
                    let cliente = data["cliente"] as? String ?? ""
                    let items = data["items"] as? [String: Int] ?? [:]
                    let entregado = data["entregado"] as? Bool ?? false
                    let total = data["total"] as? Double ?? 0.0
                    let pagado = data["pagado"] as? Bool ?? false
                    let timestamp = data["fecha"] as? Timestamp
                    let fecha = timestamp?.dateValue() ?? Date()

                    return Pedido(
                        id: doc.documentID,
                        cliente: cliente,
                        items: items,
                        total: total,
                        fecha: fecha,
                        entregado: entregado,
                        pagado: pagado
                    )
                }
            }
    }

    // Actualizar un pedido completo
    func actualizarPedido(pedido: Pedido) {
        guard let id = pedido.id else { return }

        let data: [String: Any] = [
            "cliente": pedido.cliente,
            "items": pedido.items,
            "total": pedido.total,
            "pagado": pedido.pagado,
            "entregado": pedido.entregado,
        ]

        db.collection("pedidos").document(id).updateData(data)
    }

    func marcarComoPagado(pedidoID: String) {
        db.collection("pedidos").document(pedidoID).updateData(["pagado": true])
    }

    func limpiarHistorial() {
        db.collection("pedidos").whereField("entregado", isEqualTo: true).getDocuments {
            snapshot, error in
            guard let documents = snapshot?.documents else { return }

            let batch = self.db.batch()
            for doc in documents {
                batch.deleteDocument(doc.reference)
            }

            batch.commit { error in
                if let error = error {
                    print("Error al cerrar caja: \(error.localizedDescription)")
                } else {
                    print("Cierre de caja exitoso")
                }
            }
        }
    }

    private func notificarNuevoPedido() {
        AudioServicesPlaySystemSound(1304)

        let content = UNMutableNotificationContent()
        content.title = "🔔 NUEVO PEDIDO"
        content.body = "Hay una nueva orden esperando en cocina."
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func solicitarPermisoNotificaciones() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            if granted {
                print("Permiso de notificaciones concedido")
            }
        }
    }

    // Enviar pedido a cocina
    func enviarPedido(cliente: String, carrito: [Producto], total: Double) {
        let itemsMap = Dictionary(uniqueKeysWithValues: carrito.map { ($0.nombre, $0.cantidad) })
        let nuevoPedidoData: [String: Any] = [
            "cliente": cliente,
            "items": itemsMap,
            "entregado": false,
            "total": total,
            "pagado": false,
            "fecha": FieldValue.serverTimestamp(),
        ]

        db.collection("pedidos").addDocument(data: nuevoPedidoData)

        // Restar del inventario
        for item in carrito {
            let cantidadADescontar = item.cantidad * (item.cantidadADescontar ?? 1)

            if let vinculadoID = item.vinculadoCon, !vinculadoID.isEmpty {
                // Restar del ingrediente vinculado
                db.collection("productos").document(vinculadoID).updateData([
                    "cantidad": FieldValue.increment(Int64(-cantidadADescontar))
                ])
            } else if let id = item.id {
                // Restar del producto directamente
                db.collection("productos").document(id).updateData([
                    "cantidad": FieldValue.increment(Int64(-cantidadADescontar))
                ])
            }
        }
    }

    // Marcar pedido como entregado
    func entregarPedido(pedidoID: String) {
        db.collection("pedidos").document(pedidoID).updateData(["entregado": true])
    }

    // Agregar nuevo producto al inventario
    func agregarProducto(
        nombre: String, precio: Double, categoria: String, cantidad: Int,
        vinculadoCon: String? = nil, cantidadADescontar: Int? = nil
    ) {
        var nuevoProductoData: [String: Any] = [
            "nombre": nombre,
            "precio": precio,
            "categoria": categoria,
            "cantidad": cantidad,
        ]
        if let vinculadoCon = vinculadoCon {
            nuevoProductoData["vinculadoCon"] = vinculadoCon
        }
        if let cantidadADescontar = cantidadADescontar {
            nuevoProductoData["cantidadADescontar"] = cantidadADescontar
        }

        db.collection("productos").addDocument(data: nuevoProductoData)
    }

    // Editar producto existente
    func editarProducto(
        id: String, nombre: String, precio: Double, categoria: String, cantidad: Int,
        vinculadoCon: String? = nil, cantidadADescontar: Int? = nil
    ) {
        var updateData: [String: Any] = [
            "nombre": nombre,
            "precio": precio,
            "categoria": categoria,
            "cantidad": cantidad,
        ]

        // Manejar vinculación
        if let vinculadoCon = vinculadoCon, !vinculadoCon.isEmpty {
            updateData["vinculadoCon"] = vinculadoCon
        } else {
            updateData["vinculadoCon"] = FieldValue.delete()
        }

        // Manejar cantidad a descontar
        if let cantidadADescontar = cantidadADescontar {
            updateData["cantidadADescontar"] = cantidadADescontar
        } else {
            updateData["cantidadADescontar"] = FieldValue.delete()
        }

        db.collection("productos").document(id).updateData(updateData)
    }
}
