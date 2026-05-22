package verilang.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import verilang.model.RunResult
import verilang.service.VeriLangService
import javax.swing.JFileChooser
import javax.swing.filechooser.FileNameExtensionFilter

@Composable
fun MainWindow() {
    val service = remember { VeriLangService() }
    val scope = rememberCoroutineScope()

    var filePath by remember { mutableStateOf("") }
    var result by remember { mutableStateOf<RunResult?>(null) }
    var running by remember { mutableStateOf(false) }

    val okColor = Color(0xFF2E7D32)
    val failColor = Color(0xFFC62828)
    val bg = Color(0xFF1E1E1E)
    val surface = Color(0xFF2D2D2D)
    val text = Color(0xFFEEEEEE)

    Column(
        modifier = Modifier.fillMaxSize().background(bg).padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text("VeriLang", color = text, fontSize = 22.sp)

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = filePath,
                onValueChange = { filePath = it },
                label = { Text("Archivo .vl") },
                modifier = Modifier.weight(1f),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = text,
                    unfocusedTextColor = text
                ),
                textStyle = LocalTextStyle.current.copy(fontFamily = FontFamily.Monospace)
            )
            Button(onClick = {
                val c = JFileChooser().apply {
                    fileFilter = FileNameExtensionFilter("VeriLang (*.vl)", "vl")
                }
                if (c.showOpenDialog(null) == JFileChooser.APPROVE_OPTION) {
                    filePath = c.selectedFile.absolutePath
                }
            }) { Text("Buscar") }
            Button(
                onClick = {
                    scope.launch {
                        running = true
                        result = service.run(filePath.trim())
                        running = false
                    }
                },
                enabled = filePath.isNotBlank() && !running
            ) {
                if (running) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
                else Text("Ejecutar")
            }
        }

        if (result == null) {
            Text(
                "1. Buscar → elige un programa VeriLang (.vl), p. ej. instance/example.vl\n" +
                    "2. Ejecutar → Rascal genera el JSON y aquí verás parser, módulos y resumen\n" +
                    "(El JSON se guarda solo en instance/output/verilang-ast.json)",
                color = Color(0xFF9E9E9E),
                fontSize = 13.sp,
                lineHeight = 18.sp
            )
        } else {
            ResultPanel(result!!, okColor, failColor, surface)
        }
    }
}

@Composable
private fun ResultPanel(r: RunResult, okColor: Color, failColor: Color, surface: Color) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(surface, RoundedCornerShape(8.dp))
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Requisito: estado del parser (OK / FAIL + error Rascal)
        StatusLine(
            label = "Parser",
            ok = r.parseOk,
            okColor = okColor,
            failColor = failColor,
            detail = if (!r.parseOk) r.error else null
        )

        // Requisito: lista de módulos del archivo
        val modules = r.modules.ifEmpty {
            if (r.module.isNotBlank()) listOf(r.module) else emptyList()
        }
        if (modules.isNotEmpty()) {
            Section("Módulos en el archivo", modules.joinToString("\n") { "• $it" })
        }

        // Información adicional relevante
        if (r.resumen.isNotBlank()) {
            Section("Resumen", r.resumen)
        }
        if (r.typeErrors.isNotEmpty()) {
            Section("Errores de tipos", r.typeErrors.joinToString("\n"))
        }
        if (r.parseOk && r.error.isNotBlank()) {
            Section("Error", r.error)
        }
    }
}

@Composable
private fun StatusLine(
    label: String,
    ok: Boolean,
    okColor: Color,
    failColor: Color,
    detail: String?
) {
    val color = if (ok) okColor else failColor
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            "$label: ${if (ok) "OK" else "FAIL"}",
            color = color,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace
        )
        if (!detail.isNullOrBlank()) {
            Text(detail, color = failColor, fontFamily = FontFamily.Monospace, fontSize = 13.sp)
        }
    }
}

@Composable
private fun Section(title: String, body: String) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(title, color = Color(0xFF90CAF9), fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
        Text(body, color = Color(0xFFEEEEEE), fontFamily = FontFamily.Monospace, fontSize = 13.sp)
    }
}
