# Rentia — Plan de Pruebas QA

> **Fecha:** 2026-03-19
> **Versión:** 1.0
> **Precondición general:** App instalada en dispositivo/simulador iOS 18.5+, Firebase configurado, datos de prueba cargados desde Settings → Debug → "Cargar datos de prueba"

---

## Índice

1. [Autenticación](#1-autenticación)
2. [Dashboard](#2-dashboard)
3. [Propiedades](#3-propiedades)
4. [Inquilinos](#4-inquilinos)
5. [Contratos](#5-contratos)
6. [Pagos](#6-pagos)
7. [Gastos](#7-gastos)
8. [Documentos](#8-documentos)
9. [Informes](#9-informes)
10. [Administradores](#10-administradores)
11. [Ajustes y perfil](#11-ajustes-y-perfil)
12. [Flujos cruzados (end-to-end)](#12-flujos-cruzados-end-to-end)
13. [Casos negativos y edge cases](#13-casos-negativos-y-edge-cases)

---

## 1. Autenticación

### TC-AUTH-01 — Inicio de sesión con Google
| | |
|---|---|
| **Pasos** | 1. Abrir la app en sesión cerrada. 2. Pulsar "Continuar con Google". 3. Seleccionar cuenta Google. |
| **Resultado esperado** | Se navega al Dashboard. El nombre y foto del usuario aparecen en Settings. |
| **Resultado alternativo** | Si se cancela la selección de cuenta, la app vuelve a LoginView sin error visible. |

### TC-AUTH-02 — Inicio de sesión con Apple
| | |
|---|---|
| **Pasos** | 1. Pulsar "Continuar con Apple". 2. Autenticar con Face ID / contraseña. |
| **Resultado esperado** | Se navega al Dashboard. |

### TC-AUTH-03 — Cierre de sesión
| | |
|---|---|
| **Pasos** | 1. Settings → botón "Cerrar sesión". 2. Confirmar en el diálogo. |
| **Resultado esperado** | Se navega a LoginView. Al relanzar la app muestra LoginView (no accede directamente). |

### TC-AUTH-04 — Eliminación de cuenta
| | |
|---|---|
| **Pasos** | 1. Settings → Cuenta → "Eliminar cuenta". 2. Confirmar. |
| **Resultado esperado** | Cuenta eliminada en Firebase. App navega a LoginView. |
| **⚠️ Precaución** | Ejecutar solo en cuenta de pruebas. No recuperable. |

---

## 2. Dashboard

### TC-DASH-01 — Carga de métricas
| | |
|---|---|
| **Pasos** | 1. Cargar datos dummy. 2. Navegar al Dashboard. |
| **Resultado esperado** | Las 4 tarjetas muestran valores > 0: ingresos mensuales, pagos pendientes, tasa de ocupación, inquilinos activos. |

### TC-DASH-02 — Actividad reciente
| | |
|---|---|
| **Pasos** | Ver sección "Actividad reciente" en el Dashboard. |
| **Resultado esperado** | Lista de pagos recientes ordenados por fecha descendente. No aparece estado de carga infinito. |

### TC-DASH-03 — Navegación a informes desde Dashboard
| | |
|---|---|
| **Pasos** | 1. Pulsar "Informe Anual". 2. Volver. 3. Pulsar "Informe de Deuda". |
| **Resultado esperado** | Cada informe carga correctamente y tiene botón de retorno funcional. |

### TC-DASH-04 — Pull-to-refresh
| | |
|---|---|
| **Pasos** | Hacer pull hacia abajo en el Dashboard. |
| **Resultado esperado** | Se muestra indicador de carga y los datos se recargan desde Firestore. |

---

## 3. Propiedades

### TC-PROP-01 — Listado de propiedades
| | |
|---|---|
| **Pasos** | 1. Navegar a tab Propiedades. |
| **Resultado esperado** | Se muestran las 5 propiedades dummy. Cada tarjeta muestra nombre, dirección e icono de tipo. |

### TC-PROP-02 — Búsqueda de propiedad
| | |
|---|---|
| **Pasos** | 1. Pulsar barra de búsqueda. 2. Escribir "Centro". |
| **Resultado esperado** | Solo se muestra "Apartamento Centro" y "Plaza de Garaje Centro". |

### TC-PROP-03 — Vista mapa
| | |
|---|---|
| **Pasos** | 1. Pulsar icono mapa en toolbar. |
| **Resultado esperado** | Mapa con marcadores de colores por estado. Pulsando un marcador navega al detalle. |

### TC-PROP-04 — Crear propiedad
| | |
|---|---|
| **Pasos** | 1. Pulsar "+" en toolbar. 2. Rellenar: nombre "Piso Prueba", dirección, tipo Apartamento, moneda EUR, 2 habitaciones, 1 baño. 3. Guardar. |
| **Resultado esperado** | Propiedad aparece en la lista. Al abrir el detalle todos los datos son correctos. |

### TC-PROP-05 — Editar propiedad
| | |
|---|---|
| **Pasos** | 1. Abrir "Apartamento Centro". 2. Pulsar editar. 3. Cambiar nombre a "Apartamento Centro - Editado". 4. Guardar. |
| **Resultado esperado** | El listado y el detalle muestran el nombre actualizado. |

### TC-PROP-06 — Eliminar propiedad
| | |
|---|---|
| **Pasos** | 1. Abrir "Terreno en la Sierra". 2. Pulsar eliminar → confirmar. |
| **Resultado esperado** | La propiedad desaparece del listado. |

### TC-PROP-07 — Subir fotos a propiedad
| | |
|---|---|
| **Pasos** | 1. Abrir "Apartamento Centro". 2. Sección Fotos → "Añadir fotos". 3. Seleccionar 3 fotos de la galería. |
| **Resultado esperado** | Las fotos aparecen en la galería del detalle. |
| **Requisito** | FirebaseStorage enlazado. |

### TC-PROP-08 — Eliminar foto
| | |
|---|---|
| **Pasos** | 1. Mantener pulsada una foto → "Eliminar". |
| **Resultado esperado** | La foto desaparece de la galería y de Firebase Storage. |

### TC-PROP-09 — Ver pagos de propiedad
| | |
|---|---|
| **Pasos** | 1. Detalle de "Apartamento Centro". 2. Sección Pagos → "Ver todos". |
| **Resultado esperado** | Lista con los pagos de María para esa propiedad. |

### TC-PROP-10 — Ver gastos de propiedad
| | |
|---|---|
| **Pasos** | 1. Detalle de "Apartamento Centro". 2. Sección Gastos → "Ver todos". |
| **Resultado esperado** | Lista de gastos con IBI, seguro, comunidad, etc. |

---

## 4. Inquilinos

### TC-TEN-01 — Listado de inquilinos
| | |
|---|---|
| **Pasos** | Tab Inquilinos (accesible desde Tenants o navegación). |
| **Resultado esperado** | 3 inquilinos: María (activo), Carlos (activo), Ana (inactivo con badge diferenciado). |

### TC-TEN-02 — Búsqueda de inquilino
| | |
|---|---|
| **Pasos** | Escribir "Garcia" en búsqueda. |
| **Resultado esperado** | Solo aparece "Maria Garcia Lopez". |

### TC-TEN-03 — Crear inquilino
| | |
|---|---|
| **Pasos** | 1. Pulsar "+". 2. Rellenar: nombre "Pedro", apellidos "Ruiz Gomez", email "pedro@test.com", teléfono "+34 666 000 111", estado Activo. 3. Guardar. |
| **Resultado esperado** | Inquilino aparece en la lista con estado activo. |

### TC-TEN-04 — Ver detalle de inquilino
| | |
|---|---|
| **Pasos** | Pulsar sobre "Maria Garcia Lopez". |
| **Resultado esperado** | Muestra email, teléfono, DNI, contratos activos y propiedades asociadas. |

### TC-TEN-05 — Llamar / enviar email desde detalle
| | |
|---|---|
| **Pasos** | 1. Detalle de María. 2. Pulsar el teléfono. 3. Volver y pulsar el email. |
| **Resultado esperado** | El teléfono abre la app de llamadas. El email abre Mail. |

### TC-TEN-06 — Editar inquilino
| | |
|---|---|
| **Pasos** | 1. Abrir Ana Fernandez. 2. Editar → cambiar estado a Activo. 3. Guardar. |
| **Resultado esperado** | Badge de estado actualizado en lista y detalle. |

### TC-TEN-07 — Eliminar inquilino
| | |
|---|---|
| **Pasos** | 1. Abrir "Pedro Ruiz Gomez" (creado en TC-TEN-03). 2. Eliminar → confirmar. |
| **Resultado esperado** | Inquilino desaparece de la lista. |

---

## 5. Contratos

### TC-LEASE-01 — Ver contratos desde propiedad
| | |
|---|---|
| **Pasos** | Detalle de "Apartamento Centro" → sección Contratos. |
| **Resultado esperado** | Contrato activo de María visible con fechas y importe. |

### TC-LEASE-02 — Crear contrato desde propiedad
| | |
|---|---|
| **Pasos** | 1. Detalle de "Casa Suburbia". 2. "Añadir contrato". 3. Seleccionar inquilino "Ana Fernandez", fecha inicio hoy, fecha fin en 1 año, alquiler 800€, fianza 1600€, día de facturación 1, suministros Incluidos. 4. Guardar. |
| **Resultado esperado** | Contrato en estado Borrador aparece en la sección de contratos de la propiedad. |

### TC-LEASE-03 — Activar contrato
| | |
|---|---|
| **Pasos** | 1. Abrir el contrato recién creado. 2. Pulsar "Activar". |
| **Resultado esperado** | Badge cambia a "Activo" (verde). El botón "Activar" desaparece. |

### TC-LEASE-04 — Finalizar contrato
| | |
|---|---|
| **Pasos** | 1. Abrir el contrato activo. 2. Pulsar "Finalizar". |
| **Resultado esperado** | Estado cambia a "Finalizado". |

### TC-LEASE-05 — Generar PDF del contrato
| | |
|---|---|
| **Pasos** | 1. Abrir contrato activo de María. 2. Pulsar icono PDF. |
| **Resultado esperado** | Se muestra la hoja de compartir con el PDF generado. El PDF contiene datos del contrato. |

### TC-LEASE-06 — Editar contrato
| | |
|---|---|
| **Pasos** | 1. Abrir contrato de Carlos. 2. Editar → cambiar importe a 2600€. 3. Guardar. |
| **Resultado esperado** | Detalle muestra el nuevo importe. |

---

## 6. Pagos

### TC-PAY-01 — Listado con filtros
| | |
|---|---|
| **Pasos** | 1. Tab Pagos. 2. Probar cada filtro: Todos, Pagado, Pendiente, Vencido, Parcial. |
| **Resultado esperado** | Cada filtro muestra solo los pagos con ese estado. El contador de cada chip es correcto. |

### TC-PAY-02 — Búsqueda de pago
| | |
|---|---|
| **Pasos** | Escribir "Carlos" en la barra de búsqueda. |
| **Resultado esperado** | Solo aparecen pagos asociados a Carlos Martinez. |

### TC-PAY-03 — Crear pago manual
| | |
|---|---|
| **Pasos** | 1. Pulsar "+". 2. Seleccionar inquilino "Maria Garcia", propiedad "Apartamento Centro", importe 950€, estado Pagado, método "Transferencia", fecha hoy. 3. Guardar. |
| **Resultado esperado** | Nuevo pago aparece en la lista con estado "Pagado". |

### TC-PAY-04 — Ver detalle de pago vencido
| | |
|---|---|
| **Pasos** | Filtrar por Vencido → abrir el pago de Carlos. |
| **Resultado esperado** | Badge rojo "Vencido". Fecha de vencimiento en el pasado visible. Datos del inquilino y propiedad correctos. |

### TC-PAY-05 — Editar estado de pago
| | |
|---|---|
| **Pasos** | 1. Abrir pago vencido de Carlos. 2. Editar → cambiar estado a Pagado. 3. Guardar. |
| **Resultado esperado** | Badge actualizado a "Pagado" (verde). Desaparece del filtro Vencido. |

### TC-PAY-06 — Generar PDF recibo
| | |
|---|---|
| **Pasos** | 1. Abrir cualquier pago con estado Pagado. 2. Pulsar icono PDF. |
| **Resultado esperado** | Hoja de compartir con PDF del recibo. El PDF contiene importe, fechas, inquilino y propiedad. |

### TC-PAY-07 — Eliminar pago
| | |
|---|---|
| **Pasos** | 1. Abrir el pago creado en TC-PAY-03. 2. Eliminar → confirmar. |
| **Resultado esperado** | Pago desaparece de la lista. |

---

## 7. Gastos

### TC-EXP-01 — Ver gastos de una propiedad
| | |
|---|---|
| **Pasos** | Detalle "Apartamento Centro" → Gastos → "Ver todos". |
| **Resultado esperado** | 11 gastos listados. Total visible en la tarjeta de resumen. |

### TC-EXP-02 — Filtrar gastos por categoría
| | |
|---|---|
| **Pasos** | En la lista de gastos del apartamento, seleccionar filtro "Comunidad". |
| **Resultado esperado** | Solo las cuotas de comunidad. El total se recalcula con esa selección. |

### TC-EXP-03 — Crear gasto
| | |
|---|---|
| **Pasos** | 1. Pulsar "+". 2. Importe 90€, categoría "Reparación", descripción "Cambio cerradura", fecha hoy. 3. Guardar. |
| **Resultado esperado** | Gasto aparece en la lista. Total actualizado. |

### TC-EXP-04 — Editar gasto con deslizamiento
| | |
|---|---|
| **Pasos** | Deslizar a la izquierda sobre un gasto → pulsar "Editar". |
| **Resultado esperado** | Formulario de edición con datos precargados. |

### TC-EXP-05 — Eliminar gasto con deslizamiento
| | |
|---|---|
| **Pasos** | Deslizar a la izquierda sobre el gasto creado → pulsar "Eliminar". |
| **Resultado esperado** | Gasto eliminado. Total actualizado. |

### TC-EXP-06 — Ver detalle de gasto
| | |
|---|---|
| **Pasos** | Pulsar sobre "IBI 2025 - Apartamento Centro". |
| **Resultado esperado** | Icono de categoría, importe 620€, badge "IBI", fecha correcta. |

---

## 8. Documentos

### TC-DOC-01 — Subir documento a propiedad
| | |
|---|---|
| **Pasos** | 1. Detalle "Apartamento Centro" → sección Documentos → "+". 2. Seleccionar un PDF del dispositivo. Nombre: "Escritura". Tipo: "Contrato". |
| **Resultado esperado** | Documento aparece en la lista con icono y nombre. |
| **Requisito** | FirebaseStorage enlazado. |

### TC-DOC-02 — Subir documento a inquilino
| | |
|---|---|
| **Pasos** | Detalle de María → sección Documentos → "+" → subir imagen. Tipo: "Identidad". |
| **Resultado esperado** | Documento aparece en la lista del inquilino. |

### TC-DOC-03 — Abrir/descargar documento
| | |
|---|---|
| **Pasos** | Pulsar sobre el documento subido en TC-DOC-01. |
| **Resultado esperado** | El documento se abre en el visor nativo (PDF viewer / QuickLook). |

### TC-DOC-04 — Eliminar documento
| | |
|---|---|
| **Pasos** | Pulsar icono de eliminar junto al documento → confirmar. |
| **Resultado esperado** | Documento eliminado de la lista y de Firebase Storage. |

---

## 9. Informes

### TC-REP-01 — Informe Anual
| | |
|---|---|
| **Pasos** | 1. Dashboard → "Informe Anual" (o Reports desde navegación). 2. Seleccionar el año actual. |
| **Resultado esperado** | Desglose mensual con barras proporcionales. Total anual visible. Meses sin ingresos muestran 0€. |

### TC-REP-02 — Exportar Informe Anual a CSV
| | |
|---|---|
| **Pasos** | Informe Anual → pulsar icono de exportar. |
| **Resultado esperado** | Hoja de compartir con archivo CSV. El CSV contiene columnas de mes e importe. |

### TC-REP-03 — Informe de Deuda
| | |
|---|---|
| **Pasos** | Dashboard → "Informe de Deuda". |
| **Resultado esperado** | Carlos Martinez aparece con deuda (pago vencido). El total de deuda es ≥ 2500€. María aparece como pendiente si su pago mensual está sin cobrar. |

### TC-REP-04 — Informe de Rentabilidad por propiedad
| | |
|---|---|
| **Pasos** | Detalle "Apartamento Centro" → sección Rentabilidad. Seleccionar distintos periodos. |
| **Resultado esperado** | Se muestran: ingresos, gastos y resultado neto. Al cambiar el periodo los valores se actualizan. Con datos dummy debería ser rentable. |

### TC-REP-05 — Informe de Rentabilidad — propiedad sin ingresos
| | |
|---|---|
| **Pasos** | Detalle "Terreno en la Sierra" → Rentabilidad. |
| **Resultado esperado** | Ingresos 0€, resultado negativo o cero (dependiendo de si hay gastos). No crashea. |

---

## 10. Administradores

### TC-ADM-01 — Listado de administradores
| | |
|---|---|
| **Pasos** | Propiedades → icono personas en toolbar → Administradores. |
| **Resultado esperado** | Fernando Lopez y Laura Sanchez visibles con iniciales y datos de contacto. |

### TC-ADM-02 — Crear administrador
| | |
|---|---|
| **Pasos** | 1. Pulsar "+". 2. Nombre "Rosa Perez", teléfono "+34 633 444 555", email "rosa@admin.es". 3. Guardar. |
| **Resultado esperado** | Aparece en la lista con iniciales "RP". |

### TC-ADM-03 — Contactar administrador
| | |
|---|---|
| **Pasos** | Abrir "Fernando Lopez" → pulsar teléfono / pulsar email. |
| **Resultado esperado** | Teléfono abre app de llamadas. Email abre app de correo. |

### TC-ADM-04 — Ver propiedades gestionadas
| | |
|---|---|
| **Pasos** | Detalle de "Fernando Lopez". |
| **Resultado esperado** | "Apartamento Centro" aparece en la sección de propiedades gestionadas. |

### TC-ADM-05 — Asignar administrador a propiedad
| | |
|---|---|
| **Pasos** | 1. Editar "Casa Suburbia". 2. Cambiar administrador a "Rosa Perez". 3. Guardar. |
| **Resultado esperado** | Detalle de la propiedad muestra "Rosa Perez" como administrador. El detalle de Rosa muestra "Casa Suburbia" en sus propiedades. |

### TC-ADM-06 — Eliminar administrador
| | |
|---|---|
| **Pasos** | 1. Abrir "Rosa Perez". 2. Eliminar → confirmar. |
| **Resultado esperado** | Desaparece de la lista. Las propiedades que gestionaba no muestran administrador (o muestran vacío). |

---

## 11. Ajustes y perfil

### TC-SET-01 — Ver perfil
| | |
|---|---|
| **Pasos** | Tab Settings. |
| **Resultado esperado** | Foto o placeholder, nombre y email del usuario autenticado visibles. |

### TC-SET-02 — Cambiar moneda predeterminada
| | |
|---|---|
| **Pasos** | Settings → Preferencias → Moneda → seleccionar "USD". Navegar a Propiedades. |
| **Resultado esperado** | Los importes en la app se muestran en USD. Al volver a EUR se restaura el formato. |

### TC-SET-03 — Cambiar apariencia
| | |
|---|---|
| **Pasos** | Settings → Preferencias → Apariencia → "Oscuro". |
| **Resultado esperado** | La app cambia a modo oscuro inmediatamente sin reinicios. |

### TC-SET-04 — Cambiar tamaño de texto
| | |
|---|---|
| **Pasos** | Settings → Preferencias → Tamaño de texto → "Extra Grande". |
| **Resultado esperado** | El texto en toda la app aumenta de tamaño sin romper layouts. |

### TC-SET-05 — Sección Debug (solo build DEBUG)
| | |
|---|---|
| **Pasos** | Settings → Debug → "Cargar datos de prueba". Esperar. Luego "Eliminar todos los datos". |
| **Resultado esperado** | El botón muestra spinner durante la carga. Al terminar el Dashboard refleja los nuevos datos. Eliminar borra todo. |

---

## 12. Flujos cruzados (end-to-end)

### E2E-01 — Alta completa de propiedad con contrato y pagos

```
1. Crear propiedad "Piso Test" (apartamento, Madrid)
2. Crear inquilino "Luis Torres"
3. Crear contrato para "Piso Test" con "Luis Torres", 750€/mes
4. Activar el contrato
5. Crear pago de 750€ para Luis en "Piso Test" (estado Pendiente)
6. Verificar que el Dashboard cuenta ese pago pendiente
7. Editar el pago → cambiar estado a Pagado
8. Verificar que el informe anual suma 750€ en el mes actual
```

**Resultado esperado:** Toda la cadena propiedad→inquilino→contrato→pago es coherente.

---

### E2E-02 — Propiedad con administrador, gastos e informe de rentabilidad

```
1. Crear administrador "Juan Admin"
2. Crear propiedad "Apartamento Nuevo" y asignar "Juan Admin"
3. Crear gasto de 300€ (reparación) para esa propiedad
4. Crear un pago de 900€ cobrado para esa propiedad
5. Abrir Rentabilidad de "Apartamento Nuevo"
6. Verificar: Ingresos 900€, Gastos 300€, Resultado 600€
```

---

### E2E-03 — Contrato expirado y deuda en informe

```
1. Usar los datos dummy: contrato expirado del garaje (Carlos)
2. Abrir Informe de Deuda
3. Verificar que Carlos aparece con pagos vencidos/pendientes
4. Editar el pago vencido → marcarlo como Pagado
5. Actualizar el informe de deuda
6. Verificar que la deuda de Carlos disminuye o desaparece
```

---

### E2E-04 — Subida y consulta de documentos en contrato

```
1. Abrir contrato activo de María
2. Generar PDF del contrato → compartir
3. Ir al detalle de María → sección Documentos
4. Subir ese PDF como documento tipo "Contrato"
5. Abrir el documento desde el detalle del inquilino
6. Verificar que se visualiza correctamente
```

---

## 13. Casos negativos y edge cases

### TC-NEG-01 — Formulario de propiedad vacío
| | |
|---|---|
| **Acción** | Pulsar "+" → intentar guardar sin rellenar nada. |
| **Resultado esperado** | El botón "Guardar" permanece deshabilitado. No se crea ningún documento en Firestore. |

### TC-NEG-02 — Formulario de contrato sin inquilino
| | |
|---|---|
| **Acción** | Abrir formulario de nuevo contrato → no seleccionar inquilino → intentar guardar. |
| **Resultado esperado** | El botón "Guardar" está deshabilitado. |

### TC-NEG-03 — Pago con importe 0
| | |
|---|---|
| **Acción** | Crear pago → dejar importe en 0 → intentar guardar. |
| **Resultado esperado** | Botón deshabilitado o error de validación visible. |

### TC-NEG-04 — Propiedad con más de 10 fotos
| | |
|---|---|
| **Acción** | Intentar subir una foto cuando ya hay 10. |
| **Resultado esperado** | El botón "Añadir fotos" desaparece o está deshabilitado. No se suben más de 10. |

### TC-NEG-05 — Sin conexión a internet
| | |
|---|---|
| **Acción** | Activar modo avión → abrir la app → intentar cargar propiedades. |
| **Resultado esperado** | La app no se cuelga. Muestra estado vacío o mensaje de error. No hay crash. |

### TC-NEG-06 — Eliminar propiedad con contratos activos
| | |
|---|---|
| **Acción** | Intentar eliminar "Apartamento Centro" (tiene contrato activo y pagos). |
| **Resultado esperado** | La propiedad se elimina (o se muestra advertencia). Los contratos y pagos asociados siguen en Firestore sin referencia rota visible en listas. |

### TC-NEG-07 — Doble tap en "Guardar"
| | |
|---|---|
| **Acción** | En cualquier formulario, pulsar "Guardar" dos veces muy rápido. |
| **Resultado esperado** | Solo se crea un documento en Firestore (no duplicados). El botón se deshabilita tras el primer tap. |

### TC-NEG-08 — Eliminar inquilino con contrato activo
| | |
|---|---|
| **Acción** | Eliminar "Maria Garcia Lopez". |
| **Resultado esperado** | El inquilino se elimina. En el contrato asociado el nombre puede quedar vacío, pero la app no crashea al abrir ese contrato. |

### TC-NEG-09 — Texto muy largo en campos de texto
| | |
|---|---|
| **Acción** | En el nombre de una propiedad, escribir 200 caracteres. |
| **Resultado esperado** | El texto se trunca o el campo acepta el texto sin romper el layout de las listas. |

### TC-NEG-10 — PDF sin datos de propiedad/inquilino
| | |
|---|---|
| **Acción** | Crear un pago sin propiedad asignada (si el formulario lo permite) y generar PDF. |
| **Resultado esperado** | El PDF se genera sin crashear, con campos vacíos o texto "Sin asignar". |

---

## Checklist de regresión rápida

Usar tras cualquier cambio de código para verificar que nada se rompió:

- [ ] Login y logout funcionan
- [ ] Dashboard carga métricas
- [ ] Lista de propiedades visible
- [ ] Crear y eliminar una propiedad
- [ ] Crear y eliminar un inquilino
- [ ] Crear y activar un contrato
- [ ] Crear y editar un pago
- [ ] Generar PDF de recibo
- [ ] Generar PDF de contrato
- [ ] Ver informe anual
- [ ] Ver informe de deuda
- [ ] Ver rentabilidad de propiedad
- [ ] Cambiar apariencia (claro/oscuro)
- [ ] Pull-to-refresh en al menos 2 listas

---

*Generado automáticamente a partir de la estructura de vistas y modelos del proyecto.*
