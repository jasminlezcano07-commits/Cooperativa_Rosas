// BLOQUE 3: NoSQL — MongoDB
//Colección: pedidos_whatsapp
//Motivo: los pedidos de los 3 clientes de Chiclayo llegan por
//WhatsApp con campos variables (a veces piden ramos armados,
//cintas, notas, urgencias; otras veces no) -> semiestructurado.

use CooperativaRosas;

//CREATE 
db.pedidos_whatsapp.insertMany([
  {
    fecha: "2026-01-06",
    cliente: "Mayorista Chiclayo Norte",
    items: [
      { color: "Rojo", tamano_cm: 60, paquetes: 10 },
      { color: "Blanco", tamano_cm: 50, paquetes: 5 }
    ],
    notas: "Cliente pidió ramos armados de 12 unidades",
    canal: "WhatsApp"
  },
  {
    fecha: "2026-01-08",
    cliente: "Distribuidora Flor del Valle",
    items: [ { color: "Amarillo", tamano_cm: 80, paquetes: 20 } ],
    canal: "WhatsApp"
    // sin "notas": no todos los pedidos traen ese campo
  },
  {
    fecha: "2026-01-10",
    cliente: "Comercial Rosas SAC",
    items: [
      { color: "Rosado", tamano_cm: 60, paquetes: 8 },
      { color: "Rojo", tamano_cm: 80, paquetes: 12 }
    ],
    notas: "Entregar con cinta dorada",
    canal: "WhatsApp",
    urgente: true
  }
]);

//READ 
db.pedidos_whatsapp.find({ cliente: "Mayorista Chiclayo Norte" });
db.pedidos_whatsapp.find({ "items.color": "Rojo" });

//UPDATE
db.pedidos_whatsapp.updateOne(
  { cliente: "Distribuidora Flor del Valle", fecha: "2026-01-08" },
  { $set: { notas: "Cliente confirmó recojo directo en vivero" } }
);

//DELETE
db.pedidos_whatsapp.deleteOne({ cliente: "Comercial Rosas SAC", fecha: "2026-01-10" });

