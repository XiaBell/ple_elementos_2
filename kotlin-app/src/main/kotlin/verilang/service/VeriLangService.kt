package verilang.service

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import verilang.model.RunResult
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

// RunnerJson genera verilang-ast.json; este servicio lo lee para la GUI.
class VeriLangService {

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    private val projectRoot: File by lazy {
        val cwd = File(System.getProperty("user.dir"))
        when {
            cwd.name == "kotlin-app" -> cwd.parentFile.canonicalFile
            File(cwd, "pom.xml").exists() -> cwd.canonicalFile
            else -> cwd.parentFile?.takeIf { File(it, "pom.xml").exists() }?.canonicalFile
                ?: cwd.canonicalFile
        }
    }

    private val classesDir = projectRoot.resolve("target/classes")
    private val cpFile = projectRoot.resolve("target/ple-cp.txt")
    val astJsonFile: File get() = projectRoot.resolve("instance/output/verilang-ast.json")

    suspend fun run(verilangFilePath: String): RunResult = withContext(Dispatchers.IO) {
        try {
            ensureRascalBuilt()
            runRunnerJson(verilangFilePath)
            openAstJson()
        } catch (e: Exception) {
            RunResult(parseOk = false, error = e.message ?: "Error desconocido")
        }
    }

    fun openAstJson(): RunResult {
        if (!astJsonFile.isFile) {
            throw RuntimeException(
                "No existe ${astJsonFile.absolutePath}. Ejecuta RunnerJson primero."
            )
        }
        return json.decodeFromString(astJsonFile.readText())
    }

    private fun ensureRascalBuilt() {
        if (!classesDir.isDirectory) {
            exec(listOf("mvn", "-q", "compile"), projectRoot, "mvn compile falló")
        }
        if (!cpFile.isFile) {
            exec(
                listOf("mvn", "-q", "dependency:build-classpath", "-Dmdep.outputFile=target/ple-cp.txt"),
                projectRoot,
                "No se pudo generar el classpath Maven"
            )
        }
    }

    private fun runRunnerJson(verilangFilePath: String) {
        val abs = File(verilangFilePath).canonicalPath
        val cp = listOf(classesDir.absolutePath, cpFile.readText().trim())
            .filter { it.isNotEmpty() }
            .joinToString(File.pathSeparator)

        exec(
            listOf(
                "java", "-Dfile.encoding=UTF-8", "-cp", cp,
                "org.rascalmpl.shell.RascalShell", "RunnerJson", abs
            ),
            projectRoot,
            "RunnerJson falló"
        )
    }

    private fun exec(cmd: List<String>, workDir: File, failMsg: String) {
        val process = ProcessBuilder(cmd)
            .directory(workDir)
            .redirectErrorStream(true)
            .start()

        val pool = Executors.newSingleThreadExecutor()
        try {
            val output = pool.submit<String> {
                process.inputStream.bufferedReader().readText()
            }
            if (!process.waitFor(180, TimeUnit.SECONDS)) {
                process.destroyForcibly()
                throw RuntimeException("Timeout (>180s)")
            }
            if (process.exitValue() != 0) {
                throw RuntimeException("$failMsg:\n${output.get()}")
            }
        } finally {
            pool.shutdown()
        }
    }
}
