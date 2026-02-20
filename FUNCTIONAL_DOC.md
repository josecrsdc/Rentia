# Rentia - Documento Funcional

## 1. Descripcion General

Rentia es una aplicacion iOS de gestion de propiedades en alquiler dirigida a propietarios individuales. Permite administrar propiedades, inquilinos y pagos desde un unico panel, con autenticacion social y soporte bilingue.

**Plataforma:** iOS 18.5+
**Arquitectura:** Clean MVVM (SwiftUI + @Observable)
**Backend:** Firebase (Authentication + Firestore)
**Idiomas:** Espanol (fuente) + Ingles
**Dependencias externas:** firebase-ios-sdk, GoogleSignIn-iOS

---

## 2. Flujo de Autenticacion

### 2.1 Pantalla de Login
La pantalla inicial presenta el branding de la app y dos opciones de inicio de sesion:

| Metodo | Tecnologia | Flujo |
|--------|------------|-------|
| Google Sign-In | GoogleSignIn SDK + Firebase Auth | Selector de cuenta Google > Token ID > Credencial Firebase |
| Apple Sign-In | AuthenticationServices + Firebase Auth | Sheet nativa Apple > Nonce + Token > Credencial Firebase |

**Estados:**
- Loading spinner durante autenticacion
- Alerta de error si falla el inicio de sesion
- Redireccion automatica a MainTabView al autenticarse

### 2.2 Estado de Autenticacion
- `AuthenticationState` escucha cambios en Firebase Auth en tiempo real
- La app muestra `LoadingView` mientras verifica el estado
- Sesion persistente: no requiere login al reabrir la app

---

## 3. Navegacion Principal

La app usa un `TabView` con 5 pestanas, cada una con su propio `NavigationStack`:

| # | Tab | Icono | Pantalla raiz |
|---|-----|-------|---------------|
| 1 | Dashboard | `house.fill` | DashboardView |
| 2 | Propiedades | `building.2` | PropertyListView |
| 3 | Inquilinos | `person.2` | TenantListView |
| 4 | Pagos | `creditcard` | PaymentListView |
| 5 | Ajustes | `gearshape` | SettingsView |

La navegacion interna usa enums tipados (`PropertyDestination`, `TenantDestination`, `PaymentDestination`) para navegacion type-safe.

---

## 4. Modulos Funcionales

### 4.1 Dashboard

**Pantalla:** Vista principal con resumen del portafolio.

**Tarjetas de estadisticas (4):**

| Stat | Calculo |
|------|---------|
| Ingresos Mensuales | Suma de pagos con status `paid` |
| Pagos Pendientes | Conteo de pagos `pending` + `overdue` |
| Tasa de Ocupacion | % de propiedades con status `rented` |
| Inquilinos Activos | Conteo de inquilinos con status `active` |

**Actividad reciente:**
- Ultimos 5 pagos ordenados por fecha descendente
- Pull-to-refresh para actualizar datos

**Carga de datos:** Fetch paralelo de propiedades, inquilinos y pagos.

---

### 4.2 Propiedades

**Pantallas:**

#### 4.2.1 Lista de Propiedades
- Lista de tarjetas (`PropertyCard`) con icono, nombre, direccion, status, habitaciones/banos, renta
- Barra de busqueda por nombre o direccion
- Boton (+) para crear nueva propiedad
- Estado vacio con mensaje e icono cuando no hay propiedades

#### 4.2.2 Detalle de Propiedad
- Informacion completa de la propiedad
- Inquilinos asignados
- Enlace al historial de pagos de la propiedad

#### 4.2.3 Formulario de Propiedad (Crear/Editar)
- **Informacion basica:** nombre, direccion, tipo, status
- **Asignacion de inquilino:** selector cuando status es "rented", posibilidad de crear inquilino inline
- **Financiero:** renta mensual, moneda (EUR/USD/MXN/COP)
- **Detalles:** habitaciones, banos (condicional), area, descripcion
- Validacion de formulario requerida para guardar

#### 4.2.4 Pagos de Propiedad
- Lista filtrada de pagos asociados a una propiedad especifica

**Modelo Property:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| name | String | Nombre de la propiedad |
| address | String | Direccion |
| type | PropertyType | apartment, house, commercial, garage, land |
| monthlyRent | Double | Renta mensual |
| currency | String | Moneda (EUR/USD/MXN/COP) |
| status | PropertyStatus | available, rented, maintenance |
| rooms | Int | Numero de habitaciones |
| bathrooms | Int | Numero de banos |
| area | Double? | Area en m2 |
| description | String? | Descripcion opcional |
| imageURLs | [String] | URLs de imagenes (no implementado en UI) |
| ownerId | String | ID del propietario (Firebase UID) |

**Tipos de propiedad:**

| Tipo | Icono SF | Habitaciones/Banos |
|------|----------|-------------------|
| Apartamento | `building` | Si |
| Casa | `house` | Si |
| Comercial | `storefront` | Si |
| Garaje | `car` | No (se fuerza a 0) |
| Terreno | `leaf` | No (se fuerza a 0) |

**Status de propiedad:** Disponible, Alquilada, En Mantenimiento

---

### 4.3 Inquilinos

**Pantallas:**

#### 4.3.1 Lista de Inquilinos
- Tarjetas (`TenantCard`) con avatar (iniciales), nombre, email, info de contrato, status, renta
- Busqueda por nombre o email
- Boton (+) para crear nuevo inquilino

#### 4.3.2 Detalle de Inquilino
- Datos de contacto completos
- Propiedades asignadas
- Detalles del contrato (fechas, renta, deposito)
- Historial de pagos

#### 4.3.3 Formulario de Inquilino (Crear/Editar)
- **Personal:** nombre, apellido, numero de identificacion
- **Contacto:** email (validado), telefono
- **Propiedad:** seleccion multiple de propiedades disponibles
- **Contrato:** fechas inicio/fin, renta mensual, deposito
- **Status:** activo/inactivo

**Modelo Tenant:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| firstName | String | Nombre |
| lastName | String | Apellido |
| email | String | Email (validado) |
| phone | String | Telefono |
| idNumber | String? | Numero de identificacion |
| propertyIds | [String] | IDs de propiedades asignadas |
| leaseStartDate | Date? | Inicio del contrato |
| leaseEndDate | Date? | Fin del contrato |
| monthlyRent | Double | Renta mensual |
| depositAmount | Double | Deposito |
| status | TenantStatus | active, inactive |

**Relacion:** Un inquilino puede estar asignado a multiples propiedades (many-to-many).

---

### 4.4 Pagos

**Pantallas:**

#### 4.4.1 Lista de Pagos
- Chips de filtro horizontal: Todos, Pagado, Pendiente, Vencido, Parcial
- Tarjetas (`PaymentCard`) con icono de status, monto, fecha, pill de status
- Ordenado por fecha descendente

#### 4.4.2 Detalle de Pago
- Monto y status
- Inquilino y propiedad asociados
- Fechas de pago y vencimiento
- Metodo de pago y notas

#### 4.4.3 Formulario de Pago (Crear/Editar)
- **Asignacion:** selector de inquilino y propiedad
- **Monto y status:** cantidad, estado del pago
- **Fechas:** fecha de pago, fecha de vencimiento
- **Adicional:** metodo de pago, notas (multilinea)

**Modelo Payment:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| tenantId | String | ID del inquilino |
| propertyId | String | ID de la propiedad |
| amount | Double | Monto |
| date | Date | Fecha de pago |
| dueDate | Date | Fecha de vencimiento |
| status | PaymentStatus | pending, paid, overdue, partial |
| paymentMethod | String? | Metodo de pago |
| notes | String? | Notas |

**Status de pago:**

| Status | Icono | Descripcion |
|--------|-------|-------------|
| Pendiente | `clock` | Pago registrado pero no cobrado |
| Pagado | `checkmark.circle.fill` | Pago completado |
| Vencido | `exclamationmark.triangle.fill` | Pasada la fecha de vencimiento |
| Parcial | `chart.pie` | Pago incompleto |

---

### 4.5 Ajustes

**Pantallas:**

#### 4.5.1 Vista de Ajustes
- Cabecera con perfil del usuario (nombre, email, foto)
- Enlace a Informacion de Cuenta
- Enlace a Preferencias
- Enlace a Debug (solo en builds DEBUG)
- Boton de Cerrar Sesion con dialogo de confirmacion

#### 4.5.2 Informacion de Cuenta
- Datos del usuario (de Firebase Auth)
- Boton para eliminar cuenta (borra documento Firestore + cuenta Firebase)

#### 4.5.3 Preferencias
- **Moneda por defecto:** EUR, USD, MXN, COP
- **Apariencia:** Sistema, Claro, Oscuro

#### 4.5.4 Debug (solo DEBUG)
- Cargar datos de ejemplo (5 propiedades, 3 inquilinos, ~20 pagos)
- Eliminar todos los datos del usuario

---

## 5. Modelo de Datos (Firestore)

### 5.1 Colecciones

```
firestore/
├── properties/     # Documentos de propiedades
├── tenants/        # Documentos de inquilinos
├── payments/       # Documentos de pagos
└── users/          # Perfiles de usuario (opcional)
```

### 5.2 Relaciones

```
Property ←→ Tenant    Many-to-Many (via tenant.propertyIds[])
Payment  → Tenant     Many-to-One  (via payment.tenantId)
Payment  → Property   Many-to-One  (via payment.propertyId)
*        → Owner      Many-to-One  (via *.ownerId = Firebase UID)
```

### 5.3 Queries Principales

| Operacion | Coleccion | Filtro |
|-----------|-----------|--------|
| Mis propiedades | properties | ownerId == uid |
| Mis inquilinos | tenants | ownerId == uid |
| Mis pagos | payments | ownerId == uid |
| Inquilinos de propiedad | tenants | propertyIds array-contains propertyId |
| Pagos de propiedad | payments | ownerId == uid AND propertyId == id |
| Pagos de inquilino | payments | ownerId == uid AND tenantId == id |

---

## 6. Componentes Compartidos

### 6.1 Tarjetas
| Componente | Uso |
|------------|-----|
| StatCard | Dashboard - Estadisticas con icono, valor, titulo |
| PropertyCard | Lista propiedades - Icono tipo, nombre, direccion, status, renta |
| TenantCard | Lista inquilinos - Avatar iniciales, nombre, email, contrato |
| PaymentCard | Lista pagos - Icono status, monto, fecha |

### 6.2 Formularios y Acciones
| Componente | Uso |
|------------|-----|
| PrimaryButton | Boton principal con gradiente, estado loading, sombra |
| SocialSignInButton | Boton social configurable (Google/Apple) |
| SearchBar | Campo de busqueda con icono y boton limpiar |

### 6.3 Estados
| Componente | Uso |
|------------|-----|
| EmptyStateView | Estado vacio con icono, titulo, mensaje, accion opcional |
| LoadingView | Icono de app + indicador de progreso |

---

## 7. Sistema de Diseno

### 7.1 Colores (Light/Dark)
- **Primary, Secondary, Accent** - Colores de marca
- **Background, CardBackground** - Fondos
- **Success, Warning, Error** - Semanticos
- **TextPrimary, TextSecondary, TextLight** - Texto

### 7.2 Tipografia
- Headlines: largeTitle, title, title2, title3
- Body: headline, body, callout, subheadline
- Small: footnote, caption, caption2
- Monospaced (dinero): moneyLarge, moneyMedium, moneySmall

### 7.3 Espaciado
- extraSmall: 4pt, small: 8pt, medium: 16pt
- large: 20pt, extraLarge: 24pt, xxLarge: 32pt, xxxLarge: 48pt

### 7.4 Bordes Redondeados
- Small: 8pt, Medium: 12pt, Large: 16pt, XL: 24pt, Pill: 50pt

### 7.5 Iconografia
- 100% SF Symbols (sin imagenes custom)
- Iconos de app en Assets.xcassets

---

## 8. Funcionalidades NO Implementadas

Basado en el analisis del codigo, las siguientes funcionalidades estan en el modelo pero no tienen UI o logica completa:

| Funcionalidad | Estado |
|---------------|--------|
| Imagenes de propiedades | Campo `imageURLs` existe en modelo, sin UI de carga/visualizacion |
| Perfil de usuario editable | `UserProfile` existe, se crea al guardar pero no hay edicion |
| Notificaciones push | No implementado |
| Reportes/Exportacion | No implementado |
| Busqueda global | Busqueda solo dentro de cada lista individual |
| Pagos recurrentes | No hay automatizacion, solo registro manual |
| Documentos/Contratos | No implementado |
| Multi-propietario | Diseno single-tenant (un propietario por cuenta) |

---

## 9. Estructura de Archivos

```
Rentia/
├── App/
│   ├── RentiaApp.swift              # Entry point + Firebase config
│   └── DIContainer.swift            # Inyeccion de dependencias
├── Core/
│   ├── Authentication/
│   │   ├── AuthenticationService.swift    # Protocolo + FirebaseAuthService
│   │   └── AuthenticationState.swift      # Estado observable de auth
│   ├── Firestore/
│   │   └── FirestoreService.swift         # CRUD generico Firestore
│   ├── Navigation/
│   │   ├── MainTabView.swift              # TabView principal
│   │   └── AppRouter.swift                # Destinos de navegacion
│   └── Debug/
│       └── DataSeeder.swift               # Datos de prueba (DEBUG)
├── Features/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── LoginViewModel.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   ├── Properties/
│   │   ├── Models/Property.swift
│   │   ├── ViewModels/PropertyListViewModel.swift
│   │   ├── ViewModels/PropertyFormViewModel.swift
│   │   └── Views/PropertyListView.swift
│   │   └── Views/PropertyDetailView.swift
│   │   └── Views/PropertyFormView.swift
│   │   └── Views/PropertyPaymentsView.swift
│   ├── Tenants/
│   │   ├── Models/Tenant.swift
│   │   ├── ViewModels/TenantListViewModel.swift
│   │   ├── ViewModels/TenantFormViewModel.swift
│   │   └── Views/TenantListView.swift
│   │   └── Views/TenantDetailView.swift
│   │   └── Views/TenantFormView.swift
│   ├── Payments/
│   │   ├── Models/Payment.swift
│   │   ├── ViewModels/PaymentListViewModel.swift
│   │   ├── ViewModels/PaymentFormViewModel.swift
│   │   └── Views/PaymentListView.swift
│   │   └── Views/PaymentDetailView.swift
│   │   └── Views/PaymentFormView.swift
│   └── Settings/
│       ├── ViewModels/ProfileViewModel.swift
│       └── Views/SettingsView.swift
│       └── Views/AccountInfoView.swift
│       └── Views/PreferencesView.swift
│       └── Views/DebugView.swift
├── Shared/
│   ├── Components/
│   │   ├── Cards/ (StatCard, PropertyCard, TenantCard, PaymentCard)
│   │   ├── EmptyStateView.swift
│   │   ├── LoadingView.swift
│   │   ├── PrimaryButton.swift
│   │   ├── SearchBar.swift
│   │   └── SocialSignInButton.swift
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── String+Validation.swift
│   │   ├── Date+Formatting.swift
│   │   └── Color+Theme.swift
│   ├── Models/
│   │   └── UserProfile.swift
│   └── Theme/
│       ├── AppTheme.swift
│       └── AppTypography.swift
└── Resources/
    ├── Assets.xcassets/
    └── Info.plist
```

---

## 10. Resumen Tecnico

| Aspecto | Detalle |
|---------|---------|
| Archivos Swift | ~52 |
| Pantallas | 15 (Login, Dashboard, 4x Properties, 3x Tenants, 3x Payments, 4x Settings) |
| ViewModels | 8 |
| Modelos | 4 (Property, Tenant, Payment, UserProfile) |
| Servicios | 3 (AuthService, AuthState, FirestoreService) |
| Componentes reutilizables | 9 |
| Colecciones Firestore | 4 |
| Patrones | @Observable, async/await, MainActor, Protocol DI, Type-safe Navigation |
