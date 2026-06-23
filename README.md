# DISPERSALUD IA 🌿

> **Salud rural inteligente para promotores del Cauca, Colombia**  
> Aplicación Flutter offline-first con sincronización Supabase, IA clínica y vigilancia epidemiológica SIVIGILA.

---

## 📋 Descripción

DISPERSALUD IA es una aplicación móvil diseñada para **promotores de salud en zonas rurales dispersas del Cauca**, donde la conectividad es intermitente y el acceso médico es limitado. Permite registrar, evaluar y hacer seguimiento de pacientes a lo largo de todo el ciclo de vida, con soporte de inteligencia artificial para orientación clínica y alertas epidemiológicas automatizadas.

### Contexto
- **Zona:** Cauca rural, Colombia (municipios como López de Micay, Timbiquí, Santander de Quilichao, Guapi)
- **Usuarios:** Promotores de salud comunitaria, parteras, personal de IPS
- **Conectividad:** Funciona 100% sin internet; sincroniza automáticamente cuando hay señal
- **Enfermedades prevalentes:** Dengue, Malaria, EDA, IRA, Desnutrición, Mortalidad materna

---

## ✨ Funcionalidades

### 🏥 Módulos por ciclo de vida
| Módulo | Descripción |
|--------|-------------|
| **Gestación** | Control prenatal, semanas de gestación, signos de alarma |
| **Primera Infancia (0-5 años)** | Vacunación, crecimiento, desnutrición |
| **Infancia (6-11 años)** | Desarrollo, escolarización, EDA/IRA |
| **Adolescencia (12-17 años)** | Salud mental, consumo de sustancias, ITS |
| **Juventud (18-26 años)** | Salud reproductiva, lesiones externas |
| **Adultez (27-59 años)** | Enfermedades crónicas, hipertensión, diabetes |
| **Vejez (60+)** | Polifarmacia, caídas, funcionalidad |

### 🤖 Inteligencia Artificial
- **Con internet:** Groq API (Llama 3.1-8b) — respuestas clínicas contextualizadas
- **Sin internet:** Motor local de reglas clínicas basado en protocolos del Ministerio de Salud Colombia
- Máximo 3-4 oraciones por respuesta (optimizado para uso en campo)
- Identifica emergencias y orienta remisión al médico

### 🚨 Vigilancia SIVIGILA
- Catálogo completo de eventos de notificación obligatoria
- Alertas automáticas basadas en diagnósticos registrados
- Envío automático al sistema SIVIGILA cuando hay conexión
- Seguimiento de casos por categorías: vectores, inmunoprevenibles, maternidad, infancia, ITS, zoonosis, etc.

### 📊 Dashboard epidemiológico
- Métricas en tiempo real: pacientes, consultas, alertas activas
- Tendencias por municipio y vereda
- Indicadores por módulo de ciclo de vida

### 🌐 Sincronización offline-first (Supabase)
- Todo se guarda localmente en SQLite primero
- Sincronización automática en background cuando hay internet
- Tablas sincronizadas: `pacientes`, `consultas`, `alertas`, `fichas_epidemiologicas`
- Contador de registros pendientes visible en la UI

### 📋 Fichas epidemiológicas
- Generación de fichas SIVIGILA en PDF
- Exportación a Excel
- Firma digital del profesional de salud
- Estados: borrador → completado → enviado → sincronizado

### 🌿 Saberes ancestrales y partería
- Módulo de medicina tradicional
- Integración de saberes de parteras con protocolos occidentales

### 🔒 Seguridad
- PIN de acceso con almacenamiento seguro
- Biometría (huella/Face ID) donde disponible
- Datos cifrados en tránsito con Supabase

---

## 🏗️ Arquitectura

```
lib/
├── core/
│   └── app_theme.dart              # Temas claro/oscuro, colores, extensiones
├── database/
│   └── database_helper.dart        # SQLite — fuente de verdad local (v8)
├── models/
│   ├── paciente_model.dart
│   └── gestacion_model.dart
├── screens/
│   ├── main_screen.dart            # Navegación principal
│   ├── home/home_screen.dart       # Dashboard principal
│   ├── alertas_screen.dart         # SIVIGILA + alertas epidemiológicas
│   ├── reportar_alerta_screen.dart # Formulario de reporte
│   ├── fichas_epidemiologicas_screen.dart
│   ├── modulos/                    # Módulos por ciclo de vida
│   │   ├── gestacion/
│   │   ├── primera_infancia/
│   │   ├── infancia/
│   │   ├── adolescencia/
│   │   ├── juventud/
│   │   ├── adultez/
│   │   └── vejez/
│   └── especialistas/
├── services/
│   ├── ia_service.dart             # IA híbrida (Groq + local)
│   ├── sync_service.dart           # Sincronización Supabase
│   ├── connectivity_service.dart   # Monitoreo de red
│   ├── security_service.dart       # PIN + biometría
│   ├── pdf_service.dart            # Generación de PDFs
│   └── excel_service.dart          # Exportación Excel
└── widgets/
    └── firma_panel.dart            # Captura de firma digital
```

### Patrón de datos: Offline-First

```
[Promotor] → [SQLite local] → [SyncService] → [Supabase (nube)]
                ↑                                      ↓
          Siempre funciona              Cuando hay internet
```

---

## 🛠️ Tecnologías

| Categoría | Tecnología |
|-----------|-----------|
| Framework | Flutter 3.x (Dart ≥3.3) |
| Base de datos local | SQLite (`sqflite` v2) + FFI para web |
| Backend / Nube | Supabase (PostgreSQL + Auth + Realtime) |
| IA con internet | Groq API — Llama 3.1-8b-instant (gratuito) |
| IA offline | Motor de reglas clínicas local |
| Seguridad | `flutter_secure_storage`, `local_auth`, `encrypt` |
| Voz | `speech_to_text`, `flutter_tts` |
| Audio | `record`, `audioplayers` |
| PDF | `pdf` + `printing` |
| Excel | `excel` v2 |
| GPS | `geolocator` |
| Conectividad | `connectivity_plus` |
| Gráficas | `fl_chart` |

---

## 🚀 Instalación y configuración

### Requisitos previos
- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- Android SDK (API 21+) o Xcode para iOS

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-org/dispersalud-ia.git
cd dispersalud-ia
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Supabase
Editar `lib/main.dart` con tus credenciales:
```dart
await Supabase.initialize(
  url:     'https://TU_PROYECTO.supabase.co',
  anonKey: 'tu_anon_key',
);
```

### 4. Configurar Groq API (IA con internet)
Editar `lib/services/ia_service.dart`:
```dart
static const _groqApiKey = 'tu_groq_api_key';
```
> Obtén tu clave gratuita en [console.groq.com](https://console.groq.com)

### 5. Ejecutar la aplicación
```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome

# Con modo de lanzamiento (producción)
flutter run --release
```

---

## 🗄️ Esquema de base de datos (SQLite v8)

### `pacientes`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INTEGER PK | ID local autoincremental |
| nombre | TEXT | Nombre completo |
| documento | TEXT | Cédula / ID |
| fecha_nac | TEXT | Fecha de nacimiento |
| sexo | TEXT | M / F / Otro |
| departamento | TEXT | Departamento |
| municipio | TEXT | Municipio |
| vereda | TEXT | Vereda / corregimiento |
| telefono | TEXT | Contacto |
| eps | TEXT | Aseguradora |
| modulo | TEXT | Módulo ciclo de vida |
| acudiente | TEXT | Nombre del acudiente |
| sincronizado | INTEGER | 0=pendiente, 1=sincronizado con Supabase |
| created_at | TEXT | Fecha de creación |

### `consultas`
Registros clínicos por visita: presión arterial, glucemia, peso, talla, temperatura, SpO2, FC, semanas de gestación, IMC, diagnóstico IA, nivel de riesgo, observaciones, firma digital.

### `alertas`
Alertas epidemiológicas SIVIGILA: módulo, paciente, mensaje, nivel (urgente/alerta/normal), estado resuelto, sincronizado con Supabase.

### `fichas_epidemiologicas`
Fichas de notificación obligatoria: código evento, nombre evento, datos JSON del formulario, estado (borrador/completado/enviado/sincronizado), firma profesional.

### `especialistas`
Directorio de especialistas con ciudad, teléfono, próximo horario disponible.

---

## 🌐 Tablas Supabase requeridas

Ejecutar en el SQL Editor de Supabase:

```sql
-- Pacientes
CREATE TABLE IF NOT EXISTS pacientes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_local    INTEGER UNIQUE,
  nombre      TEXT,
  documento   TEXT,
  fecha_nac   TEXT,
  sexo        TEXT,
  departamento TEXT,
  municipio   TEXT,
  vereda      TEXT,
  telefono    TEXT,
  eps         TEXT,
  modulo      TEXT,
  acudiente   TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Consultas
CREATE TABLE IF NOT EXISTS consultas (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_local        INTEGER UNIQUE,
  nombre_paciente TEXT,
  modulo          TEXT,
  fecha           TEXT,
  presion         TEXT,
  glucemia        TEXT,
  peso            TEXT,
  talla           TEXT,
  temperatura     TEXT,
  spo2            TEXT,
  fc              TEXT,
  semanas         TEXT,
  imc             TEXT,
  diagnostico     TEXT,
  nivel_riesgo    TEXT,
  observaciones   TEXT,
  datos_json      JSONB,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- Alertas SIVIGILA
CREATE TABLE IF NOT EXISTS alertas (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_local   INTEGER UNIQUE,
  modulo     TEXT,
  paciente   TEXT,
  mensaje    TEXT,
  nivel      TEXT,
  resuelta   BOOLEAN DEFAULT false,
  fecha      TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Fichas epidemiológicas
CREATE TABLE IF NOT EXISTS fichas_epidemiologicas (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_local            INTEGER UNIQUE,
  codigo_evento       TEXT,
  nombre_evento       TEXT,
  estado              TEXT,
  exportado           BOOLEAN DEFAULT false,
  datos_json          JSONB,
  nombre_paciente     TEXT,
  municipio           TEXT,
  fecha_notificacion  TEXT,
  nivel_urgencia      TEXT,
  created_at          TIMESTAMPTZ DEFAULT now()
);
```

---

## 🧪 Pruebas

```bash
# Ejecutar todos los tests
flutter test

# Tests con cobertura
flutter test --coverage

# Test específico
flutter test test/sync_service_test.dart
```

Ver carpeta `test/` para:
- `test/widget_test.dart` — Tests básicos de integración
- `test/sync_service_test.dart` — Tests del servicio de sincronización
- `test/database_helper_test.dart` — Tests de la base de datos local
- `test/ia_service_test.dart` — Tests del motor de IA offline

---

## 📱 Build para producción

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 🤝 Contribuir

1. Fork del repositorio
2. Crear rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'feat: descripción del cambio'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abrir Pull Request

---

## 📄 Licencia

Proyecto desarrollado para el sector salud del Cauca, Colombia.  
Protocolos clínicos basados en el **Instituto Nacional de Salud (INS)** y el **Ministerio de Salud de Colombia**.

---

## 📞 Contacto y soporte

- **Sistema SIVIGILA:** [www.ins.gov.co](https://www.ins.gov.co)
- **Ministerio de Salud Colombia:** [www.minsalud.gov.co](https://www.minsalud.gov.co)

---

*DISPERSALUD IA — Llevando salud inteligente a cada vereda del Cauca* 🌿