# 🌾 Finca - Aplicación Móvil

Aplicación móvil multiplataforma desarrollada en **Flutter** y **Dart** para la gestión operativa, sanitaria y administrativa de la unidad de producción ganadera. 

El sistema está diseñado para optimizar el registro de datos en campo, permitiendo el control diferenciado según los roles de trabajo y garantizando la persistencia local de la información en entornos rurales donde la conectividad a internet suele ser limitada o intermitente.

---

## 📁 Estructura del Código Fuente (`lib/`)

```text
lib/
├── main.dart                 # Inicialización de la app, temas y ruta inicial
├── login_page.dart           # Pantalla de autenticación y redirección por rol
├── home_page.dart            # Panel principal de navegación
├── database.dart             # Gestión de la base de datos y operaciones CRUD
├── administrador_pages.dart  # Vistas y lógica para el rol de Administración
├── vaquero_pages.dart        # Vistas y lógica para operaciones de campo
└── veterinario_pages.dart    # Vistas y lógica para control sanitario y salud animal
