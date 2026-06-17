import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("en") +
      // ==================== GENERAL ====================
      {
        "en": "Cancel",
        "es": "Cancelar",
      } +
      {
        "en": "Delete",
        "es": "Eliminar",
      } +
      {
        "en": "Save",
        "es": "Guardar",
      } +
      {
        "en": "Close",
        "es": "Cerrar",
      } +
      {
        "en": "Edit",
        "es": "Editar",
      } +
      {
        "en": "Create",
        "es": "Crear",
      } +
      {
        "en": "Search",
        "es": "Buscar",
      } +
      {
        "en": "Error",
        "es": "Error",
      } +
      {
        "en": "Success",
        "es": "Éxito",
      } +
      {
        "en": "Loading...",
        "es": "Cargando...",
      } +
      {
        "en": "Yes",
        "es": "Sí",
      } +
      {
        "en": "No",
        "es": "No",
      } +
      {
        "en": "Confirm",
        "es": "Confirmar",
      } +
      {
        "en": "or",
        "es": "o",
      } +
      {
        "en": "Use %s",
        "es": "Usar %s",
      } +

      // ==================== AUTH ====================
      {
        "en": "Welcome Back",
        "es": "Bienvenido de nuevo",
      } +
      {
        "en": "Sign in to continue",
        "es": "Inicia sesión para continuar",
      } +
      {
        "en": "Email",
        "es": "Correo electrónico",
      } +
      {
        "en": "Password",
        "es": "Contraseña",
      } +
      {
        "en": "Login",
        "es": "Iniciar sesión",
      } +
      {
        "en": "Register",
        "es": "Registrarse",
      } +
      {
        "en": "Logout",
        "es": "Cerrar sesión",
      } +
      {
        "en": "Create Account",
        "es": "Crear cuenta",
      } +
      {
        "en": "Sign up to get started",
        "es": "Regístrate para comenzar",
      } +
      {
        "en": "Please complete all fields",
        "es": "Por favor completa todos los campos",
      } +
      {
        "en": "Account created! Syncing in background...",
        "es": "¡Cuenta creada! Sincronizando en segundo plano...",
      } +
      {
        "en": "Register failed",
        "es": "Error en el registro",
      } +
      {
        "en": "Invalid credentials",
        "es": "Credenciales inválidas",
      } +
      {
        "en": "Logged in successfully",
        "es": "Sesión iniciada correctamente",
      } +
      {
        "en": "Logged in offline mode",
        "es": "Sesión iniciada en modo offline",
      } +
      {
        "en": "No internet connection. You need to login online at least once.",
        "es":
            "Sin conexión a internet. Necesitas iniciar sesión en línea al menos una vez.",
      } +
      {
        "en": "This user already exists locally. Please sign in.",
        "es": "Este usuario ya existe localmente. Por favor, inicia sesión.",
      } +
      {
        "en":
            "This user is already in the sync queue. Please wait for it to complete.",
        "es":
            "Este usuario ya está en la cola de sincronización. Por favor, espera a que se complete.",
      } +

      // ==================== PASSWORDS ====================
      {
        "en": "Passwords",
        "es": "Contraseñas",
      } +
      {
        "en": "Search passwords",
        "es": "Buscar contraseñas",
      } +
      {
        "en": "No passwords stored",
        "es": "No hay contraseñas guardadas",
      } +
      {
        "en": "Add Password",
        "es": "Agregar contraseña",
      } +
      {
        "en": "Edit Password",
        "es": "Editar contraseña",
      } +
      {
        "en": "Delete password?",
        "es": "¿Eliminar contraseña?",
      } +
      {
        "en": "Password deleted",
        "es": "Contraseña eliminada",
      } +
      {
        "en": "Password copied",
        "es": "Contraseña copiada",
      } +
      {
        "en": "User copied",
        "es": "Usuario copiado",
      } +
      {
        "en": "User",
        "es": "Usuario",
      } +
      {
        "en": "Title",
        "es": "Título",
      } +
      {
        "en": "Username",
        "es": "Usuario",
      } +
      {
        "en": "Website",
        "es": "Sitio web",
      } +
      {
        "en": "New Password",
        "es": "Nueva contraseña",
      } +
      {
        "en": "Confirm Password",
        "es": "Confirmar contraseña",
      } +
      {
        "en": "Current Password",
        "es": "Contraseña actual",
      } +
      {
        "en": "Please enter a title",
        "es": "Por favor ingresa un título",
      } +
      {
        "en": "Please enter a password",
        "es": "Por favor ingresa una contraseña",
      } +
      {
        "en": "Please enter a username",
        "es": "Por favor ingresa un usuario",
      } +
      {
        "en": "Website must start with http:// or https://",
        "es": "El sitio web debe comenzar con http:// o https://",
      } +
      {
        "en": "Please fix the highlighted fields",
        "es": "Por favor corrige los campos marcados",
      } +
      {
        "en": "Password created successfully",
        "es": "Contraseña creada exitosamente",
      } +
      {
        "en": "Create Password",
        "es": "Crear contraseña",
      } +
      {
        "en": "Save Changes",
        "es": "Guardar cambios",
      } +
      {
        "en": "Error saving password",
        "es": "Error al guardar contraseña",
      } +
      {
        "en": "Generate Password",
        "es": "Generar contraseña",
      } +
      {
        "en": "Password Length",
        "es": "Longitud",
      } +
      {
        "en": "Uppercase",
        "es": "Mayúsculas",
      } +
      {
        "en": "Lowercase",
        "es": "Minúsculas",
      } +
      {
        "en": "Numbers",
        "es": "Números",
      } +
      {
        "en": "Symbols",
        "es": "Símbolos",
      } +
      {
        "en": "Regenerate",
        "es": "Regenerar",
      } +
      {
        "en": "Use Password",
        "es": "Usar contraseña",
      } +
      {
        "en": "Weak",
        "es": "Débil",
      } +
      {
        "en": "Fair",
        "es": "Regular",
      } +
      {
        "en": "Strong",
        "es": "Fuerte",
      } +
      {
        "en": "Very Strong",
        "es": "Muy fuerte",
      } +
      {
        "en": "Excellent",
        "es": "Excelente",
      } +
      {
        "en": "Password generated and copied",
        "es": "Contraseña generada y copiada",
      } +
      {
        "en": "No characters selected",
        "es": "Sin caracteres seleccionados",
      } +
      {
        "en": "Empty",
        "es": "Vacía",
      } +

      // ==================== MESSAGES ====================
      {
        "en": "Messages",
        "es": "Mensajes",
      } +
      {
        "en": "No messages yet",
        "es": "Sin mensajes aún",
      } +

      // ==================== NOTES ====================
      {
        "en": "Notes",
        "es": "Notas",
      } +
      {
        "en": "Search notes",
        "es": "Buscar notas",
      } +
      {
        "en": "No notes yet",
        "es": "Aún no hay notas",
      } +
      {
        "en": "Add Note",
        "es": "Agregar nota",
      } +
      {
        "en": "Edit Note",
        "es": "Editar nota",
      } +
      {
        "en": "Delete note?",
        "es": "¿Eliminar nota?",
      } +
      {
        "en": "Note deleted",
        "es": "Nota eliminada",
      } +
      {
        "en": "Error deleting note",
        "es": "Error al eliminar nota",
      } +
      {
        "en": "Content",
        "es": "Contenido",
      } +

 // ==================== SETTINGS ====================
    {
      "en": "Settings",
      "es": "Configuración",
    } +
    {
      "en": "Profile",
      "es": "Perfil",
    } +
    {
      "en": "Hosting Mode",
      "es": "Modo de Hosting",
    } +
    {
      "en": "Update hosting mode",
      "es": "Actualizar modo de hosting",
    } +
    {
      "en": "Organization",
      "es": "Organización",
    } +
    {
      "en": "LDAP Configuration",
      "es": "Configuración LDAP",
    } +
    {
      "en": "Manage LDAP settings",
      "es": "Gestionar configuración LDAP",
    } +
    {
      "en": "Security",
      "es": "Seguridad",
    } +
    {
      "en": "Change Password",
      "es": "Cambiar contraseña",
    } +
    {
      "en": "Update your password",
      "es": "Actualiza tu contraseña",
    } +
    {
      "en": "Information",
      "es": "Información",
    } +
    {
      "en": "Application Version",
      "es": "Versión de la aplicación",
    } +
    {
      "en": "Account & Privacy",
      "es": "Cuenta y privacidad",
    } +
    {
      "en": "Privacy Policy",
      "es": "Política de Privacidad",
    } +
    {
      "en": "Cookie Policy",
      "es": "Política de Cookies",
    } +
    {
      "en": "Terms & Conditions",
      "es": "Términos y Condiciones",
    } +
    {
      "en": "Account",
      "es": "Cuenta",
    } +
    {
      "en": "Delete Account",
      "es": "Eliminar cuenta",
    } +
    {
      "en": "This action cannot be undone",
      "es": "Esta acción no se puede deshacer",
    } +
      {
        "en":
            "Are you sure you want to delete your account? This action cannot be undone.",
        "es":
            "¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.",
      } +
      {
        "en": "Are you sure you want to logout?",
        "es": "¿Estás seguro de que deseas cerrar sesión?",
      } +
      {
        "en": "Account deleted successfully",
        "es": "Cuenta eliminada exitosamente",
      } +
      {
        "en": "Error deleting account",
        "es": "Error al eliminar cuenta",
      } +
      {
        "en": "Confirm Deletion",
        "es": "Confirmar eliminación",
      } +
      {
        "en": "Enter your password to confirm account deletion.",
        "es": "Ingresa tu contraseña para confirmar la eliminación de la cuenta.",
      } +
      {
        "en": "Please enter your password",
        "es": "Por favor ingresa tu contraseña",
      } +
      {
        "en": "Please complete the new password",
        "es": "Por favor completa la nueva contraseña",
      } +
      {
        "en": "The new passwords do not match",
        "es": "Las nuevas contraseñas no coinciden",
      } +
      {
        "en": "Password must be at least 6 characters",
        "es": "La contraseña debe tener al menos 6 caracteres",
      } +
      {
        "en": "Password changed successfully",
        "es": "Contraseña cambiada exitosamente",
      } +
      {
        "en": "Failed to change password",
        "es": "Error al cambiar contraseña",
      } +
      {
        "en": "Error changing password",
        "es": "Error al cambiar contraseña",
      } +
      {
        "en": "Change",
        "es": "Cambiar",
      } +

      // ==================== DEBUG ====================
      {
        "en": "This will delete ALL local data:",
        "es": "Esto eliminará TODOS los datos locales:",
      } +
      {
        "en": "All notes",
        "es": "Todas las notas",
      } +
      {
        "en": "All passwords",
        "es": "Todas las contraseñas",
      } +
      {
        "en": "Cached credentials",
        "es": "Credenciales en caché",
      } +
      {
        "en": "Sync queue",
        "es": "Cola de sincronización",
      } +
      {
        "en": "Are you sure?",
        "es": "¿Estás seguro?",
      } +
      {
        "en": "Yes, Delete All",
        "es": "Sí, eliminar todo",
      } +
      {
        "en": "Database deleted. Restart the app.",
        "es": "Base de datos eliminada. Reinicia la aplicación.",
      } +

      // ==================== OTP ====================
      {
        "en": "Code copied",
        "es": "Código copiado",
      } +
      {
        "en": "Add OTP",
        "es": "Añadir OTP",
      } +
      {
        "en": "Account name",
        "es": "Nombre de cuenta",
      } +
      {
        "en": "Issuer",
        "es": "Emisor",
      } +
      {
        "en": "Secret key",
        "es": "Clave secreta",
      } +
      {
        "en": "Name and secret are required",
        "es": "Nombre y clave son requeridos",
      } +
      {
        "en": "Invalid secret key",
        "es": "Clave secreta inválida",
      } +
      {
        "en": "OTP added",
        "es": "OTP añadido",
      } +
      {
        "en": "Import OTP URI",
        "es": "Importar URI OTP",
      } +
      {
        "en": "Paste the otpauth:// URI from your authenticator app",
        "es": "Pega la URI otpauth:// de tu app autenticadora",
      } +
      {
        "en": "OTP URI",
        "es": "URI OTP",
      } +
      {
        "en": "Import",
        "es": "Importar",
      } +
      {
        "en": "Invalid OTP URI",
        "es": "URI OTP inválida",
      } +
      {
        "en": "OTP imported",
        "es": "OTP importado",
      } +
      {
        "en": "Delete OTP?",
        "es": "¿Eliminar OTP?",
      } +
      {
        "en": "Are you sure you want to delete",
        "es": "¿Estás seguro de que deseas eliminar",
      } +
      {
        "en": "OTP deleted",
        "es": "OTP eliminado",
      } +
      {
        "en": "Authenticator",
        "es": "Autenticador",
      } +
      {
        "en": "Import URI",
        "es": "Importar URI",
      } +
      {
        "en": "Scan QR",
        "es": "Escanear QR",
      } +
      {
        "en": "No OTP entries yet",
        "es": "Aún no hay entradas OTP",
      } +
      {
        "en": "Add your first authenticator code",
        "es": "Añade tu primer código de autenticación",
      } +
      {
        "en": "Add manually",
        "es": "Añadir manualmente",
      } +
      {
        "en": "Tap to copy",
        "es": "Toca para copiar",
      } +
      {
        "en": "Invalid OTP Entry",
        "es": "Entrada OTP inválida",
      } +
      {
        "en": "Secret key is corrupted",
        "es": "La clave secreta está corrupta",
      } +

      // ==================== SYNC ====================
      {
        "en": "Syncing in background...",
        "es": "Sincronizando en segundo plano...",
      } +
      {
        "en": "Sync complete",
        "es": "Sincronización completa",
      } +
      {
        "en": "Sync failed",
        "es": "Error de sincronización",
      } +
      {
        "en": "Offline",
        "es": "Sin conexión",
      } +
      {
        "en": "Online",
        "es": "En línea",
      } +
      {
        "en": "Sync Panel",
        "es": "Panel de Sincronización",
      } +
      {
        "en": "Registrations",
        "es": "Registros",
      } +
      {
        "en": "Sync Now",
        "es": "Sincronizar Ahora",
      } +
      {
        "en": "Syncing...",
        "es": "Sincronizando...",
      } +
      {
        "en": "Sync Successful",
        "es": "Sincronización Exitosa",
      } +
      {
        "en": "Sync Error",
        "es": "Error en Sincronización",
      } +
      {
        "en": "pending",
        "es": "pendiente",
      } +

      // ==================== AUTH ADDITIONAL ====================
      {
        "en": "Welcome",
        "es": "Bienvenido",
      } +
      {
        "en": "Sign in to your account",
        "es": "Inicia sesión en tu cuenta",
      } +
      {
        "en": "Sign In",
        "es": "Iniciar sesión",
      } +
      {
        "en": "Don't have an account? ",
        "es": "¿No tienes una cuenta? ",
      } +
      {
        "en": "Sign Up",
        "es": "Registrarse",
      } +
      {
        "en": "Already have an account? ",
        "es": "¿Ya tienes una cuenta? ",
      } +
      {
        "en": "Create account",
        "es": "Crear cuenta",
      } +
      {
        "en": "I accept the ",
        "es": "Acepto la ",
      } +
      {
        "en": " and ",
        "es": " y los ",
      } +
      {
        "en": "You must accept the terms to continue",
        "es": "Debes aceptar los términos para continuar",
      } +
      {
        "en": "Please complete email and password",
        "es": "Por favor completa el correo y contraseña",
      } +
      {
        "en": "Login failed",
        "es": "Error al iniciar sesión",
      } +
      {
        "en": "Forgot Password?",
        "es": "¿Olvidaste tu contraseña?",
      } +
      {
        "en": "Congrats! Account created successfully",
        "es": "¡Felicidades! Cuenta creada exitosamente",
      } +
      {
        "en": "Please enter your email",
        "es": "Por favor ingresa tu correo",
      } +
      {
        "en": "OTP sent to your email",
        "es": "OTP enviado a tu correo",
      } +
      {
        "en": "An error occurred",
        "es": "Ocurrió un error",
      } +
      {
        "en": "Send OTP",
        "es": "Enviar OTP",
      } +
      {
        "en": "Please enter the code",
        "es": "Por favor ingresa el código",
      } +
      {
        "en": "Code verified. Set new password.",
        "es": "Código verificado. Establece nueva contraseña.",
      } +
      {
        "en": "Invalid code",
        "es": "Código inválido",
      } +
      {
        "en": "Connection error",
        "es": "Error de conexión",
      } +
      {
        "en": "Please enter new password",
        "es": "Por favor ingresa la nueva contraseña",
      } +
      {
        "en": "Passwords do not match",
        "es": "Las contraseñas no coinciden",
      } +
      {
        "en": "Password reset successfully",
        "es": "Contraseña restablecida exitosamente",
      } +
      {
        "en": "Failed to reset password",
        "es": "Error al restablecer la contraseña",
      } +
      {
        "en": "Set New Password",
        "es": "Establecer nueva contraseña",
      } +
      {
        "en": "Verification Code",
        "es": "Código de verificación",
      } +
      {
        "en": "Please enter your new password.",
        "es": "Por favor ingresa tu nueva contraseña.",
      } +
      {
        "en": "We sent a verification code to your email.",
        "es": "Enviamos un código de verificación a tu correo.",
      } +
      {
        "en": "Verify Code",
        "es": "Verificar código",
      } +
      {
        "en": "Reset Password",
        "es": "Restablecer contraseña",
      } +
      {
        "en": "Incorrect password for local user",
        "es": "Contraseña incorrecta para usuario local",
      } +
      {
        "en": "Offline login error: %s",
        "es": "Error en login offline: %s",
      } +
      {
        "en": "No results found",
        "es": "No encontramos resultados",
      } +
      {
        "en": "No server connection and user does not exist locally",
        "es": "No hay conexión al servidor y el usuario no existe localmente",
      } +
      {
        "en": "Conversations",
        "es": "Conversaciones",
      } +
      {
        "en": "Find someone",
        "es": "Encuentra a alguien",
      } +

      // ==================== NOTES ADDITIONAL ====================
      {
        "en": "Delete Note?",
        "es": "¿Eliminar nota?",
      } +
      {
        "en": "Are you sure you want to delete",
        "es": "¿Estás seguro de que deseas eliminar",
      } +
      {
        "en": "No have notes yet",
        "es": "Aún no tienes notas",
      } +
      {
        "en": "New Note",
        "es": "Nueva nota",
      } +
      {
        "en": "A note with this title already exists",
        "es": "Ya existe una nota con este título",
      } +
      {
        "en": "Please enter the content",
        "es": "Por favor ingresa el contenido",
      } +
      {
        "en": "Error loading notes",
        "es": "Error al cargar notas",
      } +
      {
        "en": "No Content",
        "es": "Sin contenido",
      } +
      {
        "en": "No Title",
        "es": "Sin título",
      } +
      {
        "en": "Done",
        "es": "Hecho",
      } +

      // ==================== PASSWORDS ADDITIONAL ====================
      {
        "en": "Delete Password?",
        "es": "¿Eliminar contraseña?",
      } +
      {
        "en": "No passwords yet",
        "es": "Aún no hay contraseñas",
      } +
      {
        "en": "Show Password",
        "es": "Mostrar contraseña",
      } +
      {
        "en": "Hide Password",
        "es": "Ocultar contraseña",
      } +

      // ==================== HOME ====================
      {
        "en": "No data yet",
        "es": "Aún no hay datos",
      } +

      // ==================== BIOMETRIC ====================
      {
        "en": "Biometric Authentication",
        "es": "Autenticación biométrica",
      } +
      {
        "en": "Use %s to unlock app",
        "es": "Usar %s para desbloquear",
      } +
      {
        "en": "App Locked",
        "es": "App bloqueada",
      } +
      {
        "en": "Authenticate to continue",
        "es": "Autentícate para continuar",
      } +
      {
        "en": "Authenticate to access THISECURE",
        "es": "Autentícate para acceder a THISECURE",
      } +
      {
        "en": "Authenticate to enable biometric lock",
        "es": "Autentícate para activar el bloqueo biométrico",
      } +
      {
        "en": "Authenticating...",
        "es": "Autenticando...",
      } +
      {
        "en": "Tap to use %s",
        "es": "Toca para usar %s",
      } +
      {
        "en": "Biometric not available",
        "es": "Biometría no disponible",
      } +
      {
        "en": "Your device does not support biometric authentication",
        "es": "Tu dispositivo no soporta autenticación biométrica",
      } +
      {
        "en": "Biometric enabled",
        "es": "Biometría activada",
      } +
      {
        "en": "Biometric disabled",
        "es": "Biometría desactivada",
      } +
      {
        "en": "Authentication failed",
        "es": "Autenticación fallida",
      } +
      {
        "en": "Please try again",
        "es": "Por favor intenta de nuevo",
      } +

      // ==================== ONBOARDING ====================
      {
        "en": "Welcome to THISECURE",
        "es": "Bienvenido a THISECURE",
      } +
      {
        "en": "Your productivity secured manager",
        "es": "Tu gestor de productividad seguro",
      } +
      {
        "en": "Secure Storage",
        "es": "Almacenamiento seguro",
      } +
      {
        "en": "All your passwords encrypted and safe",
        "es": "Todas tus contraseñas cifradas y seguras",
      } +
      {
        "en": "Offline Access",
        "es": "Acceso sin conexión",
      } +
      {
        "en": "Access your data anytime, anywhere",
        "es": "Accede en cualquier momento y lugar",
      } +
      {
        "en": "Synchronization",
        "es": "Sincronización",
      } +
      {
        "en": "Add your first password or note",
        "es": "Agregar tu primera contraseña o nota",
      } +
      {
        "en": "Keep your data synced",
        "es": "Mantén tus datos sincronizados",
      } +
      {
        "en": "Biometric Security",
        "es": "Seguridad biométrica",
      } +
      {
        "en": "Quick and secure access with your fingerprint",
        "es": "Acceso rápido y seguro con tu huella digital",
      } +
      {
        "en": "Get Started",
        "es": "Comenzar",
      } +
      {
        "en": "Next",
        "es": "Siguiente",
      } +
      {
        "en": "Skip",
        "es": "Omitir",
      } +
      {
        "en": "Back",
        "es": "Atrás",
      } +
      {
        "en": "Password Manager",
        "es": "Gestor de contraseñas",
      } +
      {
        "en":
            "Make THISECURE your primary password manager to automatically fill in data in all your applications.",
        "es":
            "Hacer de THISECURE tu gestor de contraseñas principal para completar datos automáticamente en todas tus aplicaciones.",
      } +
      {
        "en": "Later",
        "es": "Más tarde",
      } +
      {
        "en": "Configure",
        "es": "Configurar",
      } +
      {
        "en": "LDAP Login",
        "es": "Inicio de Sesión LDAP",
      } +
      {
        "en": "Empresarial",
        "es": "Empresarial",
      } +
      {
        "en": "Enterprise email",
        "es": "Correo empresarial",
      } +
      {
        "en": "Please enter your enterprise email",
        "es": "Por favor ingrese su correo empresarial",
      } +
      {
        "en": "Use corporate domain credentials",
        "es": "Usa tus credenciales de dominio corporativo",
      } +
      {
        "en": "Use standard login",
        "es": "Usa el inicio de sesión estándar",
      } +
      {
        "en": "LDAP Configuration",
        "es": "Configuración LDAP",
      } +
      {
        "en": "Connection Settings",
        "es": "Ajustes de Conexión",
      } +
      {
        "en": "User Search & Attributes",
        "es": "Búsqueda de Usuarios y Atributos",
      } +
      {
        "en": "Enable LDAP Login",
        "es": "Habilitar Inicio de Sesión LDAP",
      } +
      {
        "en": "Test Connection",
        "es": "Probar Conexión",
      } +
      {
        "en": "Save Configuration",
        "es": "Guardar Configuración",
      } +
      {
        "en": "LDAP URL",
        "es": "URL LDAP",
      } +
      {
        "en": "Base DN",
        "es": "DN Base",
      } +
      {
        "en": "Bind DN (Optional)",
        "es": "Bind DN (Opcional)",
      } +
      {
        "en": "Bind Password (Optional)",
        "es": "Contraseña Bind (Opcional)",
      } +
      {
        "en": "User Search Filter",
        "es": "Filtro de Búsqueda de Usuarios",
      } +
      {
        "en": "Email Attribute",
        "es": "Atributo de Email",
      } +
      {
        "en": "Full Name",
        "es": "Nombre completo",
      } +
      {
        "en": "Full Name Attribute",
        "es": "Atributo de Nombre Completo",
      } +
      {
        "en": "No Organization ID found in session",
        "es": "No se encontró el ID de Organización en la sesión",
      } +
      {
        "en": "LDAP Configuration saved",
        "es": "Configuración LDAP guardada",
      } +
      {
        "en": "Enterprise Authentication",
        "es": "Autenticación Empresarial",
      } +
      {
        "en":
            "Do you want to integrate LDAP with your app for corporate domain authentication?",
        "es":
            "¿Quieres integrar LDAP para la autenticación de dominio corporativo?",
      } +
      {
        "en": "Yes, Enable LDAP",
        "es": "Sí, habilitar LDAP",
      } +
      {
        "en": "Allow users to authenticate using corporate LDAP credentials.",
        "es":
            "Permitir que los usuarios se autentiquen usando credenciales corporativas LDAP.",
      } +
      {
        "en": "No, Standard Auth",
        "es": "No, autenticación estándar",
      } +
      {
        "en": "Use regular email/password authentication.",
        "es": "Usar autenticación regular con correo y contraseña.",
      } +
{
"en":
"Configure your LDAP server details for enterprise authentication.",
"es":
"Configura los detalles de tu servidor LDAP para la autenticación empresarial.",
} +

// ==================== REGISTRO INTERACTIVO ====================
{
"en": "select_account_type",
"es": "Elige tu tipo de cuenta",
} +
{
"en": "community_account",
"es": "Community Account",
} +
{
"en": "business_account",
"es": "Business Account",
} +
{
"en": "select_deployment",
"es": "¿Cómo deseas desplegar?",
} +
{
"en": "cloud_deployment",
"es": "Cloud",
} +
{
"en": "cloud_desc",
"es": "Nosotros gestionamos la infraestructura",
} +
{
"en": "selfhosted_deployment",
"es": "Self-Hosted",
} +
{
"en": "selfhosted_desc",
"es": "Requiere servidor propio",
} +
{
"en": "back_button",
"es": "Atrás",
} +
{
"en": "continue_button",
"es": "Continuar",
} +
{
"en": "server_url_label",
"es": "URL del servidor",
} +
{
"en": "server_url_hint",
"es": "https://mi.servidor.com",
} +
{
"en": "country_optional",
"es": "País (opcional)",
} +
{
"en": "test_connection",
"es": "Probar conexión",
} +
{
"en": "testing_connection",
"es": "Probando conexión...",
} +
{
"en": "connection_success",
"es": "Conexión exitosa",
} +
{
"en": "connection_failed",
"es": "No se pudo conectar al servidor",
} +
{
    "en": "No selection",
    "es": "No seleccionar",
  } +
  {
    "en": "Completa tu registro",
    "es": "Completa tu registro",
  } +
  {
    "en": "Tu selección:",
    "es": "Tu selección:",
  } +
  {
    "en": "select_country",
    "es": "Seleccionar país",
  } +
  {
    "en": "search_country",
    "es": "Buscar país...",
  } +
  {
    "en": "clear",
    "es": "Limpiar",
  } +
  {
    "en": "no_results",
    "es": "No se encontraron resultados",
  } +

// ==================== SYSTEM SETTINGS ====================
{
  "en": "System",
  "es": "Sistema",
} +
{
  "en": "System Settings",
  "es": "Ajustes del Sistema",
} +
{
  "en": "OS-level settings and permissions for THISECURE",
  "es": "Configuraciones y permisos a nivel de SO para THISECURE",
} +
{
  "en": "Default Password Manager",
  "es": "Gestor de contraseñas principal",
} +
{
  "en": "Password Manager Status",
  "es": "Estado del gestor de contraseñas",
} +
{
  "en": "Set THISECURE as your system's default password manager to autofill credentials across all apps",
  "es": "Configura THISECURE como gestor de contraseñas principal para autorellenar credenciales en todas las apps",
} +
{
  "en": "THISECURE is your default password manager",
  "es": "THISECURE es tu gestor de contraseñas principal",
} +
{
  "en": "Open system autofill settings",
  "es": "Abrir ajustes de autofill del sistema",
} +
{
  "en": "THISECURE is not the default password manager",
  "es": "THISECURE no es el gestor de contraseñas principal",
} +
{
  "en": "Autofill not supported on this device",
  "es": "Autofill no soportado en este dispositivo",
} +
{
  "en": "App Permissions",
  "es": "Permisos de la app",
} +
{
  "en": "Open App Settings",
  "es": "Abrir Ajustes de la App",
} +
{
  "en": "Manage THISECURE permissions in system settings",
  "es": "Gestionar permisos de THISECURE en ajustes del sistema",
} +
{
  "en": "Notifications",
  "es": "Notificaciones",
} +
{
  "en": "Granted",
  "es": "Concedido",
} +
{
  "en": "Denied",
  "es": "Denegado",
} +
{
  "en": "Unknown",
  "es": "Desconocido",
} +
{
  "en": "Autofill Service",
  "es": "Servicio de Autofill",
} +
{
  "en": "Active",
  "es": "Activo",
} +
{
  "en": "Inactive",
  "es": "Inactivo",
} +
{
  "en": "Biometric Permission",
  "es": "Permiso biométrico",
} +
{
  "en": "Platform",
  "es": "Plataforma",
} +
{
  "en": "Available",
  "es": "Disponible",
} +
{
  "en": "Not available",
  "es": "No disponible",
} +
{
  "en": "Enable THISECURE as your autofill provider in system settings",
  "es": "Activa THISECURE como proveedor de autofill en los ajustes del sistema",
} +
{
  "en": "On Android, go to Settings > Passwords & accounts > Autofill service",
  "es": "En Android, ve a Ajustes > Contraseñas y cuentas > Servicio de autofill",
} +
{
  "en": "On iOS, go to Settings > Passwords > AutoFill Passwords",
  "es": "En iOS, ve a Ajustes > Contraseñas > Autorrellenar contraseñas",
} +
{
  "en": "On macOS, go to System Settings > Passwords",
  "es": "En macOS, ve a Ajustes del Sistema > Contraseñas",
} +
{
  "en": "Open System Settings",
  "es": "Abrir Ajustes del Sistema",
} +
{
  "en": "App Group Sharing",
  "es": "Compartir entre apps",
} +
{
  "en": "Share credentials with iOS/macOS credential provider extension",
  "es": "Compartir credenciales con la extensión de proveedor de iOS/macOS",
} +
{
  "en": "Credential Provider Extension",
  "es": "Extensión de proveedor de credenciales",
} +
{
  "en": "Required for system-wide autofill on iOS and macOS",
  "es": "Necesario para autofill en todo el sistema en iOS y macOS",
} +
{
  "en": "System Permissions",
  "es": "Permisos del Sistema",
} +
{
  "en": "Open system notification settings",
  "es": "Abrir ajustes de notificaciones",
} +
{
  "en": "Notification permission",
  "es": "Permiso de notificaciones",
} +
{
  "en": "Checking system settings...",
  "es": "Verificando configuración del sistema...",
} +

// ==================== MISSING UI STRINGS ====================
{
  "en": "Please enter the code",
  "es": "Por favor ingresa el código",
} +
{
  "en": "Email verified successfully",
  "es": "Correo verificado exitosamente",
} +
{
  "en": "Error verifying code",
  "es": "Error al verificar código",
} +
{
  "en": "Error resending code",
  "es": "Error al reenviar código",
} +
{
  "en": "Verify your email",
  "es": "Verifica tu correo",
} +
{
  "en": "We sent a verification code to %s. Enter it below to continue.",
  "es": "Enviamos un código de verificación a %s. Ingrésalo abajo para continuar.",
} +
{
  "en": "Send code again",
  "es": "Enviar código nuevamente",
} +
{
  "en": "Secure password manager",
  "es": "Administrador de contraseñas seguro",
} +
{
  "en": "How do I know which one to choose?",
  "es": "¿Cómo sé cuál elegir?",
} +
{
  "en": "All rights reserved.",
  "es": "Todos los derechos reservados.",
} +
{
  "en": "Verify your identity to access THISECURE",
  "es": "Verifica tu identidad para acceder a THISECURE",
} +
{
  "en": "Could not verify your identity",
  "es": "No se pudo verificar tu identidad",
} +
{
  "en": "Authentication error",
  "es": "Error de autenticación",
} +
{
  "en": "Welcome back",
  "es": "Bienvenido de nuevo",
} +
{
  "en": "Use %s to unlock",
  "es": "Usa %s para desbloquear",
} +
{
  "en": "Verifying...",
  "es": "Verificando...",
} +
{
  "en": "Use password",
  "es": "Usar contraseña",
} +
{
  "en": "Account created!",
  "es": "¡Cuenta creada!",
} +
{
  "en": "New password",
  "es": "Nueva contraseña",
} +
{
  "en": "Password saved successfully",
  "es": "Contraseña guardada correctamente",
} +
{
  "en": "Save password?",
  "es": "¿Guardar contraseña?",
} +
{
  "en": "THISECURE can save this password for you",
  "es": "THISECURE puede guardar esta contraseña para ti",
} +
{
  "en": "Title is required",
  "es": "El título es requerido",
} +
{
  "en": "User / Email",
  "es": "Usuario / Email",
} +
{
  "en": "User is required",
  "es": "El usuario es requerido",
} +
{
  "en": "Password is required",
  "es": "La contraseña es requerida",
} +
{
  "en": "Website / App",
  "es": "Sitio web / App",
} +
{
  "en": "Notes (optional)",
  "es": "Notas (opcional)",
} +
{
  "en": "Invalid QR",
  "es": "QR inválido",
} +
{
  "en": "Scan QR Code",
  "es": "Escanear código QR",
} +
{
  "en": "Copy message",
  "es": "Copiar mensaje",
} +
{
  "en": "Message copied!",
  "es": "¡Mensaje copiado!",
} +
{
  "en": "Delete message",
  "es": "Eliminar mensaje",
} +
{
  "en": "Delete message?",
  "es": "¿Eliminar mensaje?",
} +
{
  "en": "This action cannot be undone and the message will disappear for everyone.",
  "es": "Esta acción no se puede deshacer y el mensaje desaparecerá para todos.",
} +
{
  "en": "Encrypted",
  "es": "Cifrado",
} +
{
  "en": "Not encrypted",
  "es": "No cifrado",
} +
{
  "en": "Start the conversation!",
  "es": "¡Inicia la conversación!",
} +
{
  "en": "Debug & Sync",
  "es": "Debug y Sincronización",
} +
{
  "en": "Danger Zone",
  "es": "Zona de peligro",
} +
{
  "en": "Delete Local Database",
  "es": "Eliminar base de datos local",
} +
{
  "en": "Error loading passwords",
  "es": "Error al cargar contraseñas",
} +
{
  "en": "Error deleting",
  "es": "Error al eliminar",
} +
{
  "en": "Development Version",
  "es": "Versión de desarrollo",
} +
{
  "en": "Error loading logs",
  "es": "Error al cargar logs",
} +
{
  "en": "Error reading log",
  "es": "Error al leer log",
} +
{
  "en": "Clear All Logs?",
  "es": "¿Limpiar todos los logs?",
} +
{
  "en": "This will delete all log files. This action cannot be undone.",
  "es": "Esto eliminará todos los archivos de log. Esta acción no se puede deshacer.",
} +
{
  "en": "Clear",
  "es": "Limpiar",
} +
{
  "en": "All logs cleared",
  "es": "Todos los logs limpiados",
} +
{
  "en": "Log copied to clipboard",
  "es": "Log copiado al portapapeles",
} +
{
  "en": "Application Logs",
  "es": "Logs de la aplicación",
} +
{
  "en": "Copy to clipboard",
  "es": "Copiar al portapapeles",
} +
{
  "en": "Clear all logs",
  "es": "Limpiar todos los logs",
} +
{
  "en": "Refresh",
  "es": "Actualizar",
} +
{
  "en": "Log Files",
  "es": "Archivos de log",
} +
{
  "en": "No log files",
  "es": "Sin archivos de log",
} +
{
  "en": "Filter logs...",
  "es": "Filtrar logs...",
} +
{
  "en": "All Levels",
  "es": "Todos los niveles",
} +
{
  "en": "Select a log file to view",
  "es": "Selecciona un archivo de log para ver",
} +
{
  "en": "No matching logs",
  "es": "Sin logs que coincidan",
} +
{
  "en": "%s entries",
  "es": "%s entradas",
} +
{
  "en": "File: %s",
  "es": "Archivo: %s",
} +
{
  "en": "Select how you want to sign in",
  "es": "Selecciona cómo deseas ingresar",
} +
{
  "en": "Enterprise SSO",
  "es": "SSO Empresarial",
} +
{
  "en": "Corporate LDAP",
  "es": "LDAP Corporativo",
} +
{
  "en": "Enterprise account",
  "es": "Cuenta empresarial",
} +
{
  "en": "Regular Account",
  "es": "Cuenta Regular",
} +
{
  "en": "Email and password",
  "es": "Email y contraseña",
} +
{
  "en": "Continue with Google",
  "es": "Continuar con Google",
} +
{
  "en": "Continue with Microsoft",
  "es": "Continuar con Microsoft",
} +
{
  "en": "Configure AutoFill on iOS",
  "es": "Configurar AutoFill en iOS",
} +
{
  "en": "To enable THISECURE as password manager:",
  "es": "Para activar THISECURE como gestor de contraseñas:",
} +
{
  "en": "Got it",
  "es": "Entendido",
} +
{
  "en": "Password autofill",
  "es": "Autorellenado de contraseñas",
} +
{
  "en": "Select password",
  "es": "Seleccionar contraseña",
} +
{
  "en": "Autofill for:",
  "es": "Autorellenar para:",
} +
{
  "en": "Search password...",
  "es": "Buscar contraseña...",
} +
{
  "en": "No passwords found",
  "es": "No se encontraron contraseñas",
} +
{
  "en": "LDAP User",
  "es": "Usuario LDAP",
} +
{
  "en": "Organization ID",
  "es": "ID Organización",
} +
{
  "en": "Authenticated via LDAP",
  "es": "Autenticado vía LDAP",
} +
{
  "en": "Copied to clipboard",
  "es": "Copiado al portapapeles",
} +
{
  "en": "Working offline. Changes will sync when connection is restored.",
  "es": "Trabajando sin conexión. Los cambios se sincronizarán cuando se restablezca la conexión.",
} +
{
  "en": "Synced %s items",
  "es": "Sincronizados %s elementos",
} +
{
  "en": "Sync completed",
  "es": "Sincronización completada",
} +
{
  "en": "Sync failed: %s",
  "es": "Error de sincronización: %s",
} +
{
  "en": "Working offline",
  "es": "Trabajando sin conexión",
} +
{
  "en": "Back online - syncing...",
  "es": "De vuelta en línea - sincronizando...",
} +
{
  "en": "Appearance",
  "es": "Apariencia",
} +
{
  "en": "Follows device settings",
  "es": "Sigue la configuración del dispositivo",
} +
{
  "en": "Light",
  "es": "Claro",
} +
{
  "en": "Always light theme",
  "es": "Tema claro siempre activo",
} +
{
  "en": "Dark",
  "es": "Oscuro",
} +
{
  "en": "Always dark theme",
  "es": "Tema oscuro siempre activo",
} +
{
  "en": "Switch to light mode",
  "es": "Cambiar a modo claro",
} +
{
  "en": "Switch to dark mode",
  "es": "Cambiar a modo oscuro",
} +
{
  "en": "Theme",
  "es": "Tema",
} +
{
  "en": "Biometric lock",
  "es": "Bloqueo biométrico",
} +
{
  "en": "Not available on this device",
  "es": "No disponible en este dispositivo",
} +
{
  "en": "Lock with %s",
  "es": "Bloquear con %s",
} +
{
  "en": "The app will open without verification",
  "es": "La app se abrirá sin verificación",
} +
{
  "en": "Enabled",
  "es": "Activado",
} +
{
  "en": "Disabled",
  "es": "Desactivado",
} +
{
  "en": "Touch the sensor",
  "es": "Toca el sensor",
} +
{
  "en": "Look at the camera",
  "es": "Mira a la cámara",
} +
{
  "en": "Use biometrics to unlock",
  "es": "Usa biometría para desbloquear",
} +
{
  "en": "Try Again",
  "es": "Intentar de nuevo",
} +
{
  "en": "Biometric Auth",
  "es": "Autenticación biométrica",
} +
{
  "en": "Initializing...",
  "es": "Inicializando...",
} +
{
  "en": "Place your finger on the sensor",
  "es": "Coloca tu dedo en el sensor",
} +
{
  "en": "Use face or fingerprint",
  "es": "Usa rostro o huella",
} +
{
  "en": "Waiting for biometrics...",
  "es": "Esperando biometría...",
} +
{
  "en": "Touch to authenticate",
  "es": "Toca para autenticar",
} +
{
  "en": "Authenticate",
  "es": "Autenticar",
} +
{
  "en": "Authenticated",
  "es": "Autenticado",
} +
{
  "en": "No country found at this location",
  "es": "No se encontró país en esta ubicación",
} +
{
  "en": "Select Country",
  "es": "Seleccionar país",
} +
{
  "en": "Selected: %s",
  "es": "Seleccionado: %s",
} +
{
  "en": "Tap 'Confirm' to use this country",
  "es": "Toca 'Confirmar' para usar este país",
} +
{
  "en": "Could not load LDAP users",
  "es": "No se pudieron cargar usuarios LDAP",
} +
{
  "en": "New Message",
  "es": "Nuevo mensaje",
} +
{
  "en": "Enter email of the recipient",
  "es": "Ingresa el correo del destinatario",
} +
{
  "en": "Select a contact or enter an email",
  "es": "Selecciona un contacto o ingresa un correo",
} +
{
  "en": "or type email",
  "es": "o escribe un correo",
} +
{
  "en": "Start Chat",
  "es": "Iniciar chat",
} +
{
  "en": "Failed to initialize",
  "es": "Error al inicializar",
} +
{
  "en": "%s will be required when opening the app",
  "es": "Se pedirá %s al abrir la app",
} +
{
  "en": "THISECURE Secured",
  "es": "THISECURE Seguro",
} +
{
  "en": "1. Open the Settings app",
  "es": "1. Abre la app de Configuración",
} +
{
  "en": "2. Go to \"Passwords\"",
  "es": "2. Ve a 'Contraseñas'",
} +
{
  "en": "3. Tap \"AutoFill Passwords\"",
  "es": "3. Toca 'Autorrellenar contraseñas'",
} +
{
  "en": "4. Enable \"THISECURE\"",
  "es": "4. Activa 'THISECURE'",
} +
{
  "en": "After this, THISECURE can suggest passwords in Safari and other apps.",
  "es": "Después de esto, THISECURE puede sugerir contraseñas en Safari y otras apps.",
} +
{
  "en": "Are you sure you want to remove your profile picture?",
  "es": "¿Estás seguro de que deseas eliminar tu foto de perfil?",
} +
{
  "en": "Autofill for",
  "es": "Autorellenar para",
} +
{
  "en": "Autofill passwords",
  "es": "Autorrellenado de contraseñas",
} +
{
  "en": "Avatar removed",
  "es": "Avatar eliminado",
} +
{
  "en": "Avatar updated",
  "es": "Avatar actualizado",
} +
{
  "en": "Business",
  "es": "Business",
} +
{
  "en": "Choose Account Type",
  "es": "Elige tu tipo de cuenta",
} +
{
  "en": "Choose from Gallery",
  "es": "Elegir de la galería",
} +
{
  "en": "Cloud",
  "es": "Cloud",
} +
{
  "en": "Community",
  "es": "Community",
} +
{
  "en": "Continue",
  "es": "Continuar",
} +
{
  "en": "Country",
  "es": "País",
} +
{
  "en": "Country updated",
  "es": "País actualizado",
} +
{
  "en": "Delete Avatar",
  "es": "Eliminar avatar",
} +
{
  "en": "Do you want to save credentials for",
  "es": "¿Quieres guardar las credenciales para",
} +
{
  "en": "Edit Full Name",
  "es": "Editar nombre completo",
} +
{
  "en": "Enter your self-hosted server URL",
  "es": "Ingresa la URL de tu servidor",
} +
{
  "en": "Error saving note",
  "es": "Error al guardar nota",
} +
{
  "en": "For personal use. Free forever.",
  "es": "Para uso personal. Gratis para siempre.",
} +
{
  "en": "For teams and organizations.",
  "es": "Para equipos y organizaciones.",
} +
{
  "en": "Full name cannot be empty",
  "es": "El nombre no puede estar vacío",
} +
{
  "en": "Full name updated",
  "es": "Nombre completo actualizado",
} +
{
  "en": "Host on your own server. Full control.",
  "es": "Aloja en tu propio servidor. Control total.",
} +
{
  "en": "Hosted by THISECURE. Secure and managed.",
  "es": "Alojado por THISECURE. Seguro y gestionado.",
} +
{
  "en": "Lock with %s disabled",
  "es": "Bloqueo con %s desactivado",
} +
{
  "en": "Lock with %s enabled",
  "es": "Bloqueo con %s activado",
} +
{
  "en": "Log In",
  "es": "Iniciar sesión",
} +
{
  "en": "New to THISECURE? Sign up here.",
  "es": "¿Nuevo en THISECURE? Regístrate aquí.",
} +
{
  "en": "No matching passwords found",
  "es": "No se encontraron contraseñas",
} +
{
  "en": "Not set",
  "es": "No establecido",
} +
{
  "en": "Please select your country from the map",
  "es": "Selecciona tu país en el mapa",
} +
{
  "en": "Profile Picture",
  "es": "Foto de perfil",
} +
{
  "en": "Remove Photo",
  "es": "Eliminar foto",
} +
{
  "en": "Select Hosting Mode",
  "es": "Seleccionar modo de hosting",
} +
{
  "en": "Server Configuration",
  "es": "Configuración del servidor",
} +
{
  "en": "Server URL (e.g. https://api.myserver.com)",
  "es": "URL del servidor (ej. https://api.miservidor.com)",
} +
{
  "en": "t have an LDAP account, create a regular account with your email.",
  "es": "Si no tienes una cuenta LDAP, crea una cuenta regular con tu email.",
} +
{
  "en": "v1.0.2",
  "es": "v1.0.2",
} +
{
  "en": "Authentication Settings",
  "es": "Configuración de autenticación",
} +
{
  "en": "How do you want to authenticate users?",
  "es": "¿Cómo deseas autenticar a los usuarios?",
} +
{
  "en": "Deployment Mode",
  "es": "Modo de Despliegue",
} +
{
  "en": "Choose how to host your data",
  "es": "Elige cómo alojar tus datos",
} +
{
  "en": "Choose the account type",
  "es": "Elige el tipo de cuenta",
} +
{
  "en": "Note",
  "es": "Nota",
} +
{
  "en": "Start typing...",
  "es": "Empezar a escribir...",
} +
{
  "en": "Add Password",
  "es": "Agregar contraseña",
} +
{
  "en": "Import Passwords",
  "es": "Importar contraseñas",
} +
{
  "en": "Export Passwords",
  "es": "Exportar contraseñas",
} +
{
  "en": "Import from file",
  "es": "Importar desde archivo",
} +
{
  "en": "Export to file",
  "es": "Exportar a archivo",
} +
{
  "en": "CSV",
  "es": "CSV",
} +
{
  "en": "JSON",
  "es": "JSON",
} +
{
  "en": "Compatible with Bitwarden, LastPass, etc.",
  "es": "Compatible con Bitwarden, LastPass, etc.",
} +
{
  "en": "Full data format",
  "es": "Formato de datos completo",
} +
{
  "en": "Select a CSV or JSON file",
  "es": "Selecciona un archivo CSV o JSON",
} +
{
  "en": "Choose file",
  "es": "Elegir archivo",
} +
{
  "en": "Change file",
  "es": "Cambiar archivo",
} +
{
  "en": "No passwords found in file",
  "es": "No se encontraron contraseñas en el archivo",
} +
{
  "en": "Found %s passwords",
  "es": "Se encontraron %s contraseñas",
} +
{
  "en": "...and %s more",
  "es": "...y %s más",
} +
{
  "en": "Import",
  "es": "Importar",
} +
{
  "en": "Import completed",
  "es": "Importación completada",
} +
{
  "en": "Import Results",
  "es": "Resultados de importación",
} +
{
  "en": "Imported",
  "es": "Importadas",
} +
{
  "en": "Skipped (duplicates)",
  "es": "Omitidas (duplicados)",
} +
{
  "en": "Errors",
  "es": "Errores",
} +
{
  "en": "Try again",
  "es": "Intentar de nuevo",
} +
{
  "en": "Export failed",
  "es": "Error al exportar",
} +
{
  "en": "Import failed",
  "es": "Error al importar",
} +
{
  "en": "passwords will be exported",
  "es": "contraseñas se exportarán",
} +
{
  "en": "No passwords to export",
  "es": "No hay contraseñas para exportar",
} +
{
  "en": "Failed to load passwords",
  "es": "Error al cargar contraseñas",
} +
{
  "en": "Export",
  "es": "Exportar",
} +
{
  "en": "Import Notes",
  "es": "Importar notas",
} +
{
  "en": "Export Notes",
  "es": "Exportar notas",
} +
{
  "en": "Title and content",
  "es": "Título y contenido",
} +
{
  "en": "No notes to export",
  "es": "No hay notas para exportar",
} +
{
  "en": "No notes found in file",
  "es": "No se encontraron notas en el archivo",
} +
{
  "en": "Found %s notes",
  "es": "Se encontraron %s notas",
} +
{
  "en": "notes will be exported",
  "es": "notas se exportarán",
} +
{
  "en": "Failed to load notes",
  "es": "Error al cargar notas",
} +
{
  "en": "Readable text format",
  "es": "Formato de texto legible",
} +
  {
    "en": "Select a CSV, JSON, or Markdown file",
    "es": "Selecciona un archivo CSV, JSON o Markdown",
  } +

  // ==================== PASSKEYS ====================
  {
    "en": "Passkeys",
    "es": "Passkeys",
  } +
  {
    "en": "Add passkey",
    "es": "Añadir passkey",
  } +
  {
    "en": "Register passkey",
    "es": "Registrar passkey",
  } +
  {
    "en": "Delete passkey?",
    "es": "¿Eliminar passkey?",
  } +
  {
    "en": "No passkeys yet",
    "es": "Aún no hay passkeys",
  } +
  {
    "en": "Use %s to create this passkey",
    "es": "Usa %s para crear este passkey",
  } +
  {
    "en": "Passkey created",
    "es": "Passkey creada",
  } +
  {
    "en": "Passkey deleted",
    "es": "Passkey eliminada",
  } +
  {
    "en": "Passkey creation failed",
    "es": "Error al crear la passkey",
  } +
  {
    "en": "Registration cancelled",
    "es": "Registro cancelado",
  } +
  {
    "en": "Passkey name",
    "es": "Nombre de la passkey",
  } +
  {
    "en": "Add your first passkey to sign in faster",
    "es": "Añade tu primera passkey para iniciar sesión más rápido",
  } +
  {
    "en": "Backup",
    "es": "Respaldo",
  } +
  {
    "en": "Last used",
    "es": "Último uso",
  } +
  {
    "en": "Relying party",
    "es": "Parte confiante",
  } +
  {
    "en": "Never",
    "es": "Nunca",
  } +
  {
    "en": "App not associated with the server domain. The administrator must host an Apple App Site Association file at https://%s/.well-known/apple-app-site-association",
    "es": "La app no está asociada al dominio del servidor. El administrador debe hospedar un archivo Apple App Site Association en https://%s/.well-known/apple-app-site-association",
  } +
  {
    "en": "Missing or invalid AASA file on the server",
    "es": "Falta o es inválido el archivo AASA en el servidor",
  };






String get i18n => localize(this, _t);

  String i18nFor(String locale) => i18n;

  String fill(List<Object> params) => localizeFill(this, params);
}
