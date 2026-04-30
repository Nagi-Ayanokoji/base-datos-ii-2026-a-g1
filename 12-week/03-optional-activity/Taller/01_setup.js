// =============================================================
// SCRIPT 01 — Setup: crear BD, colección e insertar datos
// Taller Unidad 3 — NoSQL MongoDB
// Ejecutar en mongosh dentro del contenedor
// =============================================================

// Seleccionar (o crear) la base de datos
use mantenimiento_planta

// Limpiar colección si ya existe (útil para re-ejecutar el taller)
db.equipos.drop()

// Insertar documentos de prueba
db.equipos.insertMany([
  {
    "nombre": "Compresor A-01",
    "tipo": "Compresor industrial",
    "ubicacion": "Planta Norte",
    "estado": "Activo",
    "mantenimientos": [
      {
        "fecha": "2026-03-10",
        "tecnico": "Miyu Suzuki",
        "observacion": "Cambio de filtro de aire y lubricación general",
        "repuestos": ["Filtro HEPA FA-200", "Aceite lubricante 5W-30 (2L)"]
      },
      {
        "fecha": "2026-04-15",
        "tecnico": "Utage Kinoshita",
        "observacion": "Revisión de válvulas y ajuste de presión",
        "repuestos": ["Válvula de retención VR-12"]
      }
    ]
  },
  {
    "nombre": "Bomba Hidráulica B-03",
    "tipo": "Bomba centrífuga",
    "ubicacion": "Planta Sur",
    "estado": "En mantenimiento",
    "mantenimientos": [
      {
        "fecha": "2026-02-20",
        "tecnico": "Scarlet El Vandimion",
        "observacion": "Reemplazo de sellos mecánicos y limpieza de impeler",
        "repuestos": ["Sello mecánico SM-08", "Kit de empaque KE-04"]
      }
    ]
  },
  {
    "nombre": "Generador G-02",
    "tipo": "Generador diésel",
    "ubicacion": "Planta Norte",
    "estado": "Activo",
    "mantenimientos": [
      {
        "fecha": "2026-01-08",
        "tecnico": "Miyu Suzuki",
        "observacion": "Cambio de aceite y filtros",
        "repuestos": ["Filtro de aceite FO-55", "Aceite diésel 15W-40 (5L)"]
      },
      {
        "fecha": "2026-03-25",
        "tecnico": "Utage Kinoshita",
        "observacion": "Calibración del regulador de voltaje",
        "repuestos": ["Regulador de voltaje RV-220"]
      }
    ]
  }
])

// Verificar inserción
print("Total de equipos insertados:", db.equipos.countDocuments())
