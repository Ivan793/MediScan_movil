allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Quitar el bloque "java { }" — no se usa en Flutter Android

// ✅ Reubicar la configuración del directorio de compilación
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// ✅ Tarea de limpieza estándar
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
