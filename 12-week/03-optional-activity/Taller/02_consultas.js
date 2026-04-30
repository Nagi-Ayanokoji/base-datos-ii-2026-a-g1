// =============================================================
// SCRIPT 02 — Consultas básicas (Actividad 3)
// Taller Unidad 3 — NoSQL MongoDB
// =============================================================

use mantenimiento_planta

// -----------------------------------------------------------
// Consulta 1 — Equipos por sede (ubicacion exacta)
// -----------------------------------------------------------
print("=== Consulta 1: Equipos en Planta Norte ===")
db.equipos.find(
  { "ubicacion": "Planta Norte" },
  { "nombre": 1, "tipo": 1, "estado": 1, "ubicacion": 1, "_id": 0 }
).forEach(printjson)


// -----------------------------------------------------------
// Consulta 2 — Búsqueda por palabra clave con $regex
// Busca equipos cuyo nombre contenga "Compresor"
// -----------------------------------------------------------
print("\n=== Consulta 2: Equipos cuyo nombre contiene 'Compresor' ===")
db.equipos.find(
  {
    "nombre": {
      $regex: "Compresor",
      $options: "i"   // i = case-insensitive
    }
  },
  { "nombre": 1, "tipo": 1, "estado": 1, "_id": 0 }
).forEach(printjson)


// -----------------------------------------------------------
// Consulta 3 — Equipos con mantenimiento de un técnico específico
// Usa dot notation para buscar dentro del arreglo de subdocumentos
// -----------------------------------------------------------
print("\n=== Consulta 3: Equipos con mantenimiento de 'Miyu Suzuki' ===")
db.equipos.find(
  { "mantenimientos.tecnico": "Miyu Suzuki" },
  { "nombre": 1, "mantenimientos.tecnico": 1, "mantenimientos.fecha": 1, "_id": 0 }
).forEach(printjson)


// -----------------------------------------------------------
// EXTRA — Equipos con mantenimiento de 'Scarlet El Vandimion'
// -----------------------------------------------------------
print("\n=== Extra: Equipos atendidos por 'Scarlet El Vandimion' ===")
db.equipos.find(
  { "mantenimientos.tecnico": "Scarlet El Vandimion" },
  { "nombre": 1, "ubicacion": 1, "_id": 0 }
).forEach(printjson)
