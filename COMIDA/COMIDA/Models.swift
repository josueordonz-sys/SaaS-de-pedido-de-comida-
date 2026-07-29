import FirebaseFirestore
import Foundation

struct Producto: Identifiable, Codable {
    var id: String?
    var nombre: String
    var precio: Double
    var categoria: String  // "Comida" o "Bebida"
    var cantidad: Int
    var vinculadoCon: String?  // ID del producto del que depende el stock
    var cantidadADescontar: Int?  // Cuanto descontar del inventario (por defecto 1)
}

struct Pedido: Identifiable, Codable {
    var id: String?
    var cliente: String
    var items: [String: Int]  // Nombre del producto y cantidad
    var total: Double = 0.0
    var fecha: Date = Date()
    var entregado: Bool = false
    var pagado: Bool = false
}
