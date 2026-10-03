# Relwo — Repositorio Documental Capstone

Repositorio documental del proyecto de título **Relwo**, desarrollado para la asignatura **Portafolio de Título (Capstone - PTY4614)** de la carrera **Ingeniería en Informática** en **Duoc UC, Sede Plaza Norte**.

Este espacio centraliza las evidencias de aprendizaje, actas, entregables técnicos y la documentación de avance del proyecto para la revisión y seguimiento continuo por parte del docente a lo largo del semestre académico.

---

## 👥 Equipo de Trabajo

* **Mauricio Poblete**
* **Tania Sáez**
* **Nayareth Suárez**

---

## 📱 Acerca del Proyecto: Relwo

**Relwo** es una plataforma tecnológica concebida para formalizar, transparentar y asegurar la contratación de servicios y oficios para el hogar (gasfitería, cerrajería, electricidad, limpieza, entre otros).

### Problemática y Propuesta de Valor
En Chile, la contratación de servicios domésticos independientes suele realizarse mediante canales informales sin verificación de identidad ni garantías de cumplimiento. Relwo soluciona este problema mediante:
* **Verificación de prestadores:** Registro y validación de antecedentes de los profesionales para generar confianza en el cliente.
* **Seguridad en las transacciones:** Esquema de pago retenido (*escrow*), donde el dinero permanece bajo custodia y se libera al prestador únicamente cuando ambas partes manifiestan conformidad con el trabajo realizado.
* **Transparencia y cobertura:** Estandarización de tarifas bases, cotizaciones integradas y geolocalización por cobertura comunal.

### Arquitectura y Componentes Tecnológicos
* **Aplicación Móvil:** Desarrollada en **Flutter**, con interfaces especializadas para clientes y prestadores de servicios.
* **Panel Web de Administración:** Desarrollado en **Angular**, orientado a la supervisión operativa, resolución de controversias y validación de perfiles.
* **Servicio Backend & API REST:** Construido con **NestJS** y **TypeScript**.
* **Base de Datos:** Motor relacional **PostgreSQL**.
* **Integración de Pagos:** Conexión con pasarela de pagos en entorno de pruebas implementando retención de fondos.

---

## 📂 Estructura del Repositorio

El repositorio se encuentra estructurado en tres fases secuenciales correspondientes al ciclo académico, manteniendo en cada una la separación estricta entre evidencias grupales e individuales:

```text
relwo-capstone/
├── Fase 1/                         # Definición y Planificación del Proyecto (Semanas 1 a 4)
│   ├── Evidencias grupales/        # Definición del proyecto APT, Carta Gantt, presentación y prototipo navegable
│   ├── Evidencias individuales/    # Autoevaluaciones de competencias (1.1, 1.3) y diarios de reflexión (1.2)
│   └── README.md                   # Detalle e información de la Fase 1
│
├── Fase 2/                         # Desarrollo y Ejecución (Semanas 5 a 14)
│   ├── Evidencias grupales/        # Arquitectura, modelo de datos, backend/API, app móvil, panel y plan de pruebas
│   ├── Evidencias individuales/    # Autoevaluaciones intermedias, reflexiones y bitácoras de trabajo
│   └── README.md                   # Detalle e información de la Fase 2
│
└── Fase 3/                         # Cierre y Evaluación (Semanas 15 a 18)
    ├── Evidencias grupales/        # Pruebas en dispositivos físicos, despliegue en entorno de pruebas y presentación final
    ├── Evidencias individuales/    # Autoevaluación final de competencias y reflexiones de cierre
    └── README.md                   # Detalle e información de la Fase 3
```

---

## 🔗 Entregables y Recursos Destacados

* [Prototipo navegable web](Fase%201/Evidencias%20grupales/Prototipo%20navegable%20web.md) — Documento con acceso al prototipo interactivo de navegación de flujos.
* [Carta Gantt del Proyecto](Fase%201/Evidencias%20grupales/Carta_Gantt_Relwo.xlsx) — Planificación semestral de actividades, hitos, asignación de responsabilidades y dependencias.
* [Guía de Definición del Proyecto APT](Fase%201/Evidencias%20grupales/1.5_GuiaEstudiante_Fase%201_Definicion%20Proyecto%20APT) — Fundamentación del proyecto, alcance técnico, pertinencia y competencias asociadas.

---

## 📌 Convenciones de Entrega

* **Evidencias grupales:** Informes técnicos, minutas, diagramas de arquitectura y presentaciones consensuadas por el equipo.
* **Evidencias individuales:** Formatos institucionales correspondientes a las entregas de cada integrante (`[Nombre]_[Apellido]-[Código]_[Asignatura]_[Tipo].docx`).
