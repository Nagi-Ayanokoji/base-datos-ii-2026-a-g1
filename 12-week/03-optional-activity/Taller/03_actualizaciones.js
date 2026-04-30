// =============================================================
// SCRIPT 03 — Actualizaciones con updateOne() (Actividad 4)
// Taller Unidad 3 — NoSQL MongoDB
// =============================================================

use mantenimiento_planta

// -----------------------------------------------------------
// Actualización 1 — Cambiar el estado de un equipo
// Cambia la Bomba Hidráulica B-03 de "En mantenimiento" a "Activo"
// -----------------------------------------------------------
print("=== Antes de actualizar estado ===")
db.equipos.find(
  { "nombre": "Bomba Hidráulica B-03" },
  { "nombre": 1, "estado": 1, "_id": 0 }
).forEach(printjson)

db.equipos.updateOne(
  { "nombre": "Bomba Hidráulica B-03" },
  {
    $set: { "estado": "Activo" }
  }
)

print("\n=== Después de actualizar estado ===")
db.equipos.find(
  { "nombre": "Bomba Hidráulica B-03" },
  { "nombre": 1, "estado": 1, "_id": 0 }
).forEach(printjson)


// -----------------------------------------------------------
// Actualización 2 — Agregar nuevo mantenimiento al arreglo
// $push añade el subdocumento al final del arreglo sin borrar los anteriores
// -----------------------------------------------------------
print("\n=== Agregando nuevo mantenimiento al Compresor A-01 ===")

db.equipos.updateOne(
  { "nombre": "Compresor A-01" },
  {
    $push: {
      "mantenimientos": {
        "fecha": "2026-04-30",
        "tecnico": "Scarlet El Vandimion",
        "observacion": "Inspección general post-cuarentena preventiva",
        "repuestos": ["Correa de transmisión CT-44", "Empaque de culata EC-01"]
      }
    }
  }
)

print("\n=== Historial de mantenimientos del Compresor A-01 (actualizado) ===")
db.equipos.find(
  { "nombre": "Compresor A-01" },
  { "nombre": 1, "mantenimientos": 1, "_id": 0 }
).forEach(printjson)
