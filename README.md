# Gastos del negocio

Versión para empresas de "Mis gastos". Cada empresa entra con su propio usuario y ve su nombre, logo, colores y categorías.

## Puesta en marcha (una sola vez)

1. Crea un proyecto nuevo en [Supabase](https://supabase.com), distinto del de la app personal.
2. En **SQL Editor**, pega y ejecuta todo el archivo `supabase.sql`.
3. En **Authentication > Sign In / Providers**, desactiva **Allow new users to sign up**. Solo tú creas las cuentas.
4. En **Project Settings > API**, copia la *Project URL* y la clave *publishable/anon*. Pégalas al inicio del `<script>` de `index.html` (`SUPABASE_URL` y `SUPABASE_KEY`).
5. Publica `index.html` en cualquier hosting estático (GitHub Pages, Netlify, Vercel).

## Dar de alta una empresa

1. **Authentication > Users > Add user**: crea un correo y una contraseña para el cliente.
2. **Storage > logos**: sube su logo y copia la URL pública.
3. Ejecuta el `insert` de ejemplo que está al final de `supabase.sql` con los datos de la empresa: nombre, logo, colores en formato `#RRGGBB` y, si quieres, sus categorías.

Para cambiar algo después, edita la fila en **Table Editor > empresas**. El cliente verá el cambio la próxima vez que inicie sesión.

## Ideas para más adelante

- Chat de IA con Gemini. La API key no debe ir en `index.html`, porque cualquiera podría verla. Hay que llamarla desde una *Edge Function* de Supabase.
