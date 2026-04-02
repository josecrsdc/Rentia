# QA Tasks — Rentia

> Documento generado el 2026-03-24. Usar como referencia para resolver los issues encontrados durante QA.
> Prioridades: 🔴 Crítico · 🟠 Alto · 🟡 Medio

---

## Índice

| # | Tarea | Prioridad | Estado |
|---|-------|-----------|--------|
| T-01 | Navegación tras eliminar no vuelve a la lista | 🟠 Alto | ✅ Completado |
| T-02 | Añadir tipo de propiedad "Estudio" | 🟡 Medio | ✅ Completado |
| T-03 | Formulario propiedad — etiquetas siempre visibles en campos de detalle | 🟡 Medio | ⬜ Pendiente |
| T-04 | Formulario inquilino — email sin mayúsculas y con teclado correcto | 🟡 Medio | ⬜ Pendiente |
| T-05 | Formulario inquilino — acceso a contactos del dispositivo | 🟡 Medio | ⬜ Pendiente |
| T-06 | Formulario contrato — renombrar campos financieros y añadir moneda | 🟠 Alto | ⬜ Pendiente |
| T-07 | Error en formulario de pago al editar: contrato no encontrado | 🔴 Crítico | ⬜ Pendiente |
| T-08 | Lista de pagos — filtro por propiedad y cambio de estado múltiple | 🟠 Alto | ✅ Completado |
| T-09 | Formulario pago — formato de cantidad con moneda del contrato | 🟡 Medio | ⬜ Pendiente |
| T-10 | Lista de pagos — filtro por mes | 🟡 Medio | ✅ Completado |
| T-11 | Botón "generar factura" debe guardar el PDF como documento del pago | 🟠 Alto | ⬜ Pendiente |
| T-12 | Ajustes — sección de configuración de datos de factura | 🟠 Alto | ⬜ Pendiente |
| T-13 | Dashboard — ingresos mensuales calcula el total anual | 🔴 Crítico | ⬜ Pendiente |
| T-14 | Dashboard — selector mes / año para las métricas | 🟠 Alto | ⬜ Pendiente |
| T-15 | Nuevo gasto — botón muestra "common.save" y no guarda (Firestore permissions) | 🔴 Crítico | ⬜ Pendiente |
| T-16 | Dashboard — "Pendiente" en propiedad solo para el mes en curso | 🟡 Medio | ⬜ Pendiente |
| T-17 | Dashboard — Estado de deuda: solo mostrar si el mes ya ha pasado sin pago | 🟡 Medio | ⬜ Pendiente |

---

## Detalle de tareas

---

### T-01 · Navegación tras eliminar no vuelve a la lista

**Prioridad:** 🟠 Alto
**Afecta a:** Propiedades, Inquilinos, Administradores, Pagos

**Descripción:**
Al eliminar un elemento desde su vista de edición (formulario), la app no navega de vuelta a la lista. La vista de detalle sigue mostrándose aunque el registro ya no exista en Firestore.

**Causa probable:**
El `didSave`/`didDelete` flag se activa pero el `dismiss()` no se llama, o la NavigationStack no está procesando el pop correctamente después del delete asíncrono.

**Archivos relevantes:**
- `Rentia/Features/Properties/ViewModels/PropertyFormViewModel.swift`
- `Rentia/Features/Tenants/ViewModels/TenantFormViewModel.swift`
- `Rentia/Features/Administrators/ViewModels/AdministratorFormViewModel.swift`
- `Rentia/Features/Payments/ViewModels/PaymentFormViewModel.swift`
- Vistas correspondientes (`PropertyFormView`, `TenantFormView`, etc.)

**Solución esperada:**
Tras un delete exitoso, llamar `dismiss()` en la vista del formulario Y, si aplica, hacer pop del detalle en la NavigationStack para que no quede en pila una vista de detalle del elemento ya eliminado.

---

### T-02 · Añadir tipo de propiedad "Estudio"

**Prioridad:** 🟡 Medio
**Afecta a:** Formulario de nueva/editar propiedad

**Descripción:**
El enum `PropertyType` no incluye el tipo "estudio" (studio apartment). Hay que añadirlo como opción de selección.

**Archivos relevantes:**
- `Rentia/Features/Properties/Models/Property.swift` (línea 7 — enum `PropertyType`)
- `Rentia/Resources/Localizable.xcstrings`

**Implementación:**
1. Añadir `case studio` en `PropertyType`.
2. Añadir `localizedName` → `"properties.type.studio"` y el icono apropiado (e.g. `"bed.double"`).
3. Decidir si `supportsRoomsBathrooms` aplica → sí aplica.
4. Añadir strings en `es` y `en` en `Localizable.xcstrings`.

---

### T-03 · Formulario propiedad — etiquetas siempre visibles en campos de detalle

**Prioridad:** 🟡 Medio
**Afecta a:** `PropertyFormView` (sección de detalles), potencialmente otros formularios

**Descripción:**
En la sección de detalles del formulario de propiedad, cuando los campos tienen valor, no se ve a qué corresponde cada campo (no hay etiqueta visible). El usuario no sabe qué dato está editando.

**Solución esperada:**
Crear un componente reutilizable `LabeledTextField` (o similar) que muestre siempre la etiqueta encima del campo `TextField`, independientemente de si está vacío o no. Consistente con el diseño `cardStyle()` de la app.

```
[Etiqueta]
[Campo de texto con valor o placeholder]
```

**Archivos relevantes:**
- `Rentia/Features/Properties/Views/PropertyFormView.swift`
- `Rentia/Shared/Components/` — crear nuevo componente aquí
- Revisar si `TenantFormView`, `LeaseFormView`, `ExpenseFormView` necesitan el mismo componente.

---

### T-04 · Formulario inquilino — email sin mayúsculas y teclado de email

**Prioridad:** 🟡 Medio
**Afecta a:** `TenantFormView`

**Descripción:**
El campo de correo electrónico al crear inquilino activa la primera letra en mayúsculas (`autocapitalization`) y no usa el teclado de tipo email (`keyboardType(.emailAddress)`).

**Archivos relevantes:**
- `Rentia/Features/Tenants/Views/TenantFormView.swift`

**Implementación:**
```swift
TextField("tenants.email", text: $email)
    .keyboardType(.emailAddress)
    .autocorrectionDisabled()
    .textInputAutocapitalization(.never)
```

---

### T-05 · Formulario inquilino — acceso a contactos del dispositivo para el teléfono

**Prioridad:** 🟡 Medio
**Afecta a:** `TenantFormView`

**Descripción:**
Al crear un inquilino, el usuario quiere poder seleccionar un contacto del dispositivo para rellenar el número de teléfono automáticamente.

**Implementación:**
1. Añadir `NSContactsUsageDescription` en `Info.plist` con string localizado.
2. Usar `CNContactPickerViewController` (via `UIViewControllerRepresentable`) o el nuevo `ContactAccessButton` si se apunta a iOS 18+.
3. Al seleccionar un contacto, rellenar `phone` y opcionalmente `name`/`email` si están vacíos.

**Archivos relevantes:**
- `Rentia/Features/Tenants/Views/TenantFormView.swift`
- `Rentia/Features/Tenants/ViewModels/TenantFormViewModel.swift`
- `Rentia/Shared/Components/` — añadir wrapper `ContactPickerButton` si se usa UIViewControllerRepresentable

---

### T-06 · Formulario contrato — renombrar campos financieros y añadir selector de moneda

**Prioridad:** 🟠 Alto
**Afecta a:** `LeaseFormView`, modelo `Lease`

**Descripción:**
En la sección financiera del formulario de contrato:
- "Monto de la renta" → renombrar a **"Mensualidad"**
- "Monto de depósito" → renombrar a **"Fianza depositada"**
- Añadir selector de **moneda** (€ Euro / $ Dólar) para cada campo, con el formato numérico correspondiente.

**Modelo `Lease` — cambios:**
El modelo actualmente no tiene campo `currency`. Hay que añadirlo:
```swift
var currency: String  // "EUR" | "USD"
```

**Archivos relevantes:**
- `Rentia/Features/Leases/Models/Lease.swift`
- `Rentia/Features/Leases/Views/LeaseFormView.swift`
- `Rentia/Features/Leases/ViewModels/LeaseFormViewModel.swift`
- `Rentia/Resources/Localizable.xcstrings`

**Notas:**
- La moneda del contrato debe propagarse a `PaymentFormViewModel` para formatear cantidades correctamente (ver T-09).
- El formato monetario debe usar `Locale` apropiado: `€1.150,00` para EUR, `$1,150.00` para USD.

---

### T-07 · Error en formulario de pago al editar: "no hay contrato activo"

**Prioridad:** 🔴 Crítico
**Afecta a:** `PaymentFormView` / `PaymentFormViewModel`

**Descripción:**
Al editar un pago existente, el formulario muestra el aviso en rojo "no hay ningún contrato activo para esta combinación de inquilino y propiedad", aunque el contrato existe y fue el que generó ese pago.

**Causa raíz (confirmada):**
En `loadPayment(id:)` (línea 103), se asigna `tenantId` y `propertyId`, lo que dispara `didSet → autoFillFromLease()`. En ese momento, `leases` podría estar vacío porque `loadData()` es asíncrono y aún no ha terminado. El resultado es `activeLease = nil`, lo que hace que `isFormValid` sea `false` y la UI muestre el error.

**Archivos relevantes:**
- `Rentia/Features/Payments/ViewModels/PaymentFormViewModel.swift` (líneas 103–132, 184–211)

**Solución esperada:**
Garantizar que `loadData()` se complete antes de llamar `loadPayment(id:)`, o bien llamar `autoFillFromLease()` al final de `loadData()` cuando ya se tienen los leases cargados y hay un `editingPaymentId` activo.

---

### T-08 · Lista de pagos — filtro por propiedad y cambio de estado múltiple

**Prioridad:** 🟠 Alto
**Afecta a:** `PaymentListView`, `PaymentListViewModel`

**Descripción:**
La lista de pagos necesita:
1. **Filtro por propiedad**: selector de 1 o más propiedades para mostrar solo sus pagos.
2. **Selección múltiple**: poder seleccionar varios pagos y cambiar su estado en bloque (e.g. marcar como pagados).

**Archivos relevantes:**
- `Rentia/Features/Payments/Views/PaymentListView.swift`
- `Rentia/Features/Payments/ViewModels/PaymentListViewModel.swift`

**Implementación:**
- Añadir `Set<String>` de `selectedPropertyIds` en el ViewModel, con un picker/menu de propiedades.
- Añadir modo de selección múltiple (`isSelecting: Bool`) con checkboxes en cada fila.
- Acción de toolbar "Cambiar estado" que muestra un picker con los estados posibles y actualiza en Firestore todos los seleccionados.

---

### T-09 · Formulario de pago — formato de cantidad según moneda del contrato

**Prioridad:** 🟡 Medio
**Afecta a:** `PaymentFormView`, `PaymentFormViewModel`

**Descripción:**
El campo de cantidad en el formulario de pago no formatea ni indica la moneda (EUR/USD) que corresponde al contrato asociado. El usuario no sabe en qué moneda está introduciendo el importe.

**Archivos relevantes:**
- `Rentia/Features/Payments/ViewModels/PaymentFormViewModel.swift`
- `Rentia/Features/Payments/Views/PaymentFormView.swift`

**Implementación:**
- Exponer `activeLease?.currency` en el ViewModel.
- Mostrar el símbolo de moneda junto al campo de importe.
- Formatear el placeholder y la visualización según la locale de la moneda.
- Depende de T-06 (añadir `currency` al modelo `Lease`).

---

### T-10 · Lista de pagos — filtro por mes

**Prioridad:** 🟡 Medio
**Afecta a:** `PaymentListView`, `PaymentListViewModel`

**Descripción:**
Añadir la posibilidad de filtrar los pagos por mes (e.g. "Marzo 2026"), mostrando solo los pagos cuya `dueDate` corresponda al mes seleccionado.

**Archivos relevantes:**
- `Rentia/Features/Payments/Views/PaymentListView.swift`
- `Rentia/Features/Payments/ViewModels/PaymentListViewModel.swift`

**Implementación:**
- Selector de mes/año en la toolbar o como filtro pill.
- Por defecto mostrar el mes en curso.
- Combinar con el filtro de propiedad de T-08.

---

### T-11 · Botón "generar factura" debe guardar el PDF como documento del pago

**Prioridad:** 🟠 Alto
**Afecta a:** `PaymentDetailView`, `PDFGeneratorService`

**Descripción:**
El botón de generar factura/recibo genera el PDF pero no lo persiste. El PDF generado debe guardarse como un `Document` asociado al pago en Firestore/Storage, igual que los documentos adjuntos a propiedades/inquilinos/contratos.

**Archivos relevantes:**
- `Rentia/Features/Payments/Views/PaymentDetailView.swift`
- `Rentia/Core/Services/PDFGeneratorService.swift` (si existe) o similar
- `Rentia/Features/Documents/Models/Document.swift`
- `Rentia/Features/Documents/Views/DocumentListView.swift`

**Implementación:**
1. Tras generar el PDF, subirlo a Firebase Storage en path `documents/payments/{paymentId}/{filename}.pdf`.
2. Crear un registro `Document` en Firestore con `entityType: .payment` y `entityId: paymentId`.
3. Mostrar los documentos del pago en `PaymentDetailView` (sección documentos).
4. Requiere datos de factura configurados (ver T-12).

---

### T-12 · Ajustes — sección de configuración de datos de factura

**Prioridad:** 🟠 Alto
**Afecta a:** `SettingsView`, nuevo `InvoiceSettingsView`

**Descripción:**
Crear una sección en Ajustes para que el usuario configure sus datos de emisor de facturas/recibos.

**Campos a incluir:**
- Logo (imagen desde galería)
- Nombre / Razón social
- NIF / CIF
- Dirección fiscal
- Teléfono de contacto
- Email de contacto
- Número de cuenta bancaria (para pagos por transferencia)
- Número de factura inicial / correlativo automático

**Archivos relevantes:**
- `Rentia/Features/Settings/Views/SettingsView.swift`
- Crear `Rentia/Features/Settings/Views/InvoiceSettingsView.swift`
- Crear `Rentia/Features/Settings/ViewModels/InvoiceSettingsViewModel.swift`

**Persistencia:**
Guardar en Firestore en colección `userSettings/{userId}/invoiceProfile` o bien en `UserDefaults`/`Keychain` para datos locales.

---

### T-13 · Dashboard — ingresos mensuales calcula el total anual

**Prioridad:** 🔴 Crítico
**Afecta a:** `DashboardViewModel`

**Descripción:**
`totalMonthlyIncome` suma **todos** los pagos con estado `.paid` sin filtrar por fecha. Con un alquiler de 1.150 €/mes y 9 pagos pagados, muestra 10.350 € en lugar de 1.150 €.

**Causa raíz (confirmada):**
`DashboardViewModel.totalMonthlyIncome` (línea 19) no filtra por mes en curso:
```swift
// ACTUAL — incorrecto
var totalMonthlyIncome: Double {
    payments.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }
}
```

**Archivos relevantes:**
- `Rentia/Features/Dashboard/ViewModels/DashboardViewModel.swift` (línea 19)

**Solución:**
```swift
var totalMonthlyIncome: Double {
    let calendar = Calendar.current
    let now = Date()
    return payments
        .filter {
            $0.status == .paid
            && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        .reduce(0) { $0 + $1.amount }
}
```
> Nota: cuando se implemente T-14 (selector mes/año), el filtro deberá usar el período seleccionado en lugar de `Date()`.

---

### T-14 · Dashboard — selector de período (mes / año)

**Prioridad:** 🟠 Alto
**Afecta a:** `DashboardView`, `DashboardViewModel`

**Descripción:**
Las métricas del Dashboard (ingresos, pagos pendientes, etc.) deben poder visualizarse filtrando por mes concreto o por año completo. El usuario debe poder navegar entre períodos.

**Archivos relevantes:**
- `Rentia/Features/Dashboard/Views/DashboardView.swift`
- `Rentia/Features/Dashboard/ViewModels/DashboardViewModel.swift`

**Implementación:**
- Añadir `selectedPeriod: DashboardPeriod` (enum `.month(Date)` / `.year(Int)`) al ViewModel.
- Controles de navegación (← mes anterior / mes siguiente →) y toggle mes/año en la cabecera del Dashboard.
- Todas las métricas calculadas (`totalMonthlyIncome`, `pendingPaymentsCount`, etc.) deben respetar el período seleccionado.

---

### T-15 · Nuevo gasto — botón muestra "common.save" y no guarda (Firestore permissions)

**Prioridad:** 🔴 Crítico
**Afecta a:** `ExpenseFormView`, Firebase Firestore Rules

**Descripción:**
Dos problemas combinados:

1. **UI**: El botón de guardar muestra la clave de localización `common.save` en lugar del texto traducido. Falta añadir esa clave en `Localizable.xcstrings`.

2. **Firestore**: Al pulsar guardar, la operación falla con:
   ```
   [FirebaseFirestore] Write at expenses/{id} failed: Missing or insufficient permissions.
   ```
   Las reglas de Firestore no permiten escritura en la colección `expenses`.

**Archivos relevantes:**
- `Rentia/Resources/Localizable.xcstrings` — añadir clave `common.save`
- `Rentia/Features/Expenses/Views/ExpenseFormView.swift` — verificar uso de la clave
- Firebase Console → Firestore → Rules — añadir regla para colección `expenses`

**Regla Firestore a añadir:**
```
match /expenses/{expenseId} {
  allow read, write: if request.auth != null
      && request.auth.uid == resource.data.ownerId;
  allow create: if request.auth != null
      && request.auth.uid == request.resource.data.ownerId;
}
```

---

### T-16 · Dashboard — badge "Pendiente" en propiedad solo para el mes en curso

**Prioridad:** 🟡 Medio
**Afecta a:** `DashboardView` / `DashboardViewModel`

**Descripción:**
Una propiedad muestra "Pendiente" si tiene pagos pendientes hasta el final del contrato. El usuario quiere que solo se muestre si hay pagos pendientes **del mes en curso o anteriores** (no futuros).

**Archivos relevantes:**
- `Rentia/Features/Dashboard/ViewModels/DashboardViewModel.swift`
- `Rentia/Features/Dashboard/Views/DashboardView.swift`

**Solución:**
Filtrar los pagos pendientes por `dueDate <= fin del mes en curso`:
```swift
let endOfCurrentMonth = Calendar.current.date(
    byAdding: .month, value: 1,
    to: Calendar.current.startOfMonth(for: Date())
)!
payments.filter {
    ($0.status == .pending || $0.status == .overdue)
    && $0.dueDate <= endOfCurrentMonth
}
```

---

### T-17 · Dashboard — Estado de deuda: solo si el mes ha pasado sin pagar

**Prioridad:** 🟡 Medio
**Afecta a:** `DashboardView`, `DebtReportView`, `DashboardViewModel`

**Descripción:**
El apartado "Estado de la deuda" puede marcar como deuda pagos cuya fecha de vencimiento aún no ha llegado. Solo debe considerarse deuda un pago cuando:
- Su `dueDate` ya ha pasado (es anterior a hoy), **Y**
- Su estado es `.pending` o `.overdue`

Un pago pendiente para el mes que viene **no es deuda**.

**Archivos relevantes:**
- `Rentia/Features/Dashboard/ViewModels/DashboardViewModel.swift`
- `Rentia/Features/Reports/ViewModels/DebtReportViewModel.swift`
- `Rentia/Features/Reports/Views/DebtReportView.swift`

**Solución:**
```swift
var overduePayments: [Payment] {
    let today = Date()
    return payments.filter {
        ($0.status == .pending || $0.status == .overdue)
        && $0.dueDate < today
    }
}
```

---

## Notas de dependencias

```
T-06 (moneda en contrato) → T-09 (formato moneda en pago)
T-06 (moneda en contrato) → T-11 (factura con moneda correcta)
T-12 (config factura)     → T-11 (usar datos en PDF generado)
T-13 (fix ingresos)       → T-14 (selector período reutiliza el fix)
T-08 (filtro propiedad)   → T-10 (filtro mes + propiedad combinados)
T-15 (Firestore rules)    — independiente, resolver primero
T-07 (bug pago edit)      — independiente, resolver primero
```
