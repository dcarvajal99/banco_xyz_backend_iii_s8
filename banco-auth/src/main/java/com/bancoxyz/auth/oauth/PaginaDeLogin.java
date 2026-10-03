package com.bancoxyz.auth.oauth;

import java.util.Map;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.client.registration.ClientRegistration;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.util.HtmlUtils;

/**
 * Formulario de inicio de sesion del Banco XYZ. Es la unica pagina donde el usuario escribe su clave: la aplicacion
 * cliente nunca la ve (flujo authorization_code). Lleva el token CSRF del formulario. Si GitHub esta configurado, ofrece
 * tambien "Ingresar con GitHub" ({@code /oauth2/authorization/github}): GitHub autentica y banco-auth emite sus tokens.
 */
@Controller
class PaginaDeLogin {

    /** Valor por omision del client-id mientras no se registre la aplicacion OAuth en GitHub. */
    static final String SIN_CONFIGURAR = "sin-configurar";

    private final ObjectProvider<ClientRegistrationRepository> registros;

    PaginaDeLogin(ObjectProvider<ClientRegistrationRepository> registros) {
        this.registros = registros;
    }

    private static final Map<String, String> MENSAJES = Map.of(
            "credenciales", "Usuario o clave incorrectos.",
            "bloqueado", "El usuario esta bloqueado. Contacte al banco.",
            "no-habilitado", "Este usuario no puede iniciar sesion en la banca en linea.",
            "servicio", "El servicio de autenticacion no esta disponible. Intente en unos segundos.",
            "github-no-vinculado", "Su cuenta de GitHub no esta vinculada a un cliente del banco.",
            "github", "No se pudo iniciar sesion con GitHub. Intente nuevamente.");

    @GetMapping(value = "/login", produces = MediaType.TEXT_HTML_VALUE)
    @ResponseBody
    String formulario(@RequestParam(required = false) String error, CsrfToken csrf) {
        String aviso = error == null ? "" : "<p class=\"error\" role=\"alert\">"
                + HtmlUtils.htmlEscape(MENSAJES.getOrDefault(error, MENSAJES.get("credenciales"))) + "</p>";
        String github = !githubConfigurado() ? "" : "<div class=\"o\">o</div>\n"
                + "<a class=\"github\" href=\"oauth2/authorization/github\">Ingresar con GitHub</a>\n";
        return """
                <!doctype html>
                <html lang="es"><head><meta charset="utf-8"><title>Banco XYZ - Iniciar sesion</title>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                 body{font-family:-apple-system,"Segoe UI",Helvetica,Arial,sans-serif;background:#f3f6f4;margin:0;display:flex;
                  min-height:100vh;align-items:center;justify-content:center;color:#1d2a24}
                 main{background:#fff;border:1px solid #d9e3de;border-radius:12px;padding:32px 36px;width:340px}
                 h1{font-size:20px;color:#215E3E;margin:0 0 4px} p.sub{font-size:13px;color:#5b6660;margin:0 0 20px}
                 label{display:block;font-size:13px;margin:12px 0 4px} input{width:100%%;box-sizing:border-box;padding:9px 10px;
                  border:1px solid #b9c7c0;border-radius:6px;font-size:14px}
                 button{margin-top:20px;width:100%%;padding:10px;border:0;border-radius:6px;background:#215E3E;color:#fff;
                  font-size:15px;cursor:pointer} p.error{background:#fdecea;color:#8a1f11;border-radius:6px;padding:8px 10px;font-size:13px}
                 p.pie{font-size:11.5px;color:#6b7a73;margin:18px 0 0}
                 div.o{text-align:center;color:#6b7a73;font-size:12px;margin:14px 0 0}
                 a.github{display:block;margin-top:10px;padding:9px;border:1px solid #24292f;border-radius:6px;color:#24292f;
                  text-align:center;text-decoration:none;font-size:14px;font-weight:600}
                </style></head><body><main>
                <h1>Banco XYZ</h1><p class="sub">Inicie sesion para autorizar a la banca en linea</p>
                %s
                <form method="post" action="login">
                 <label for="username">Usuario</label><input id="username" name="username" autocomplete="username" required autofocus>
                 <label for="password">Clave</label><input id="password" name="password" type="password" autocomplete="current-password" required>
                 <input type="hidden" name="%s" value="%s">
                 <button type="submit">Ingresar</button>
                </form>
                %s<p class="pie">Servidor de autorizacion OAuth 2.0 · su clave la verifica el banco, la aplicacion no la recibe.</p>
                </main></body></html>
                """.formatted(aviso, csrf.getParameterName(), csrf.getToken(), github);
    }

    private boolean githubConfigurado() {
        ClientRegistrationRepository repositorio = registros.getIfAvailable();
        ClientRegistration github = repositorio == null ? null : repositorio.findByRegistrationId("github");
        return github != null && !SIN_CONFIGURAR.equals(github.getClientId());
    }
}
