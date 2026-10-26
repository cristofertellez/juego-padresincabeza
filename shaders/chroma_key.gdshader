shader_type canvas_item;

/**
 * Shader de Chroma Key para Pixel Art 2D
 * Elimina automáticamente fondos con color clave (#FF00FF Magenta)
 * Incluye eliminación de halos / rebote de color (despill) para evitar bordes rosados.
 */

uniform vec4 key_color : source_color = vec4(1.0, 0.0, 1.0, 1.0); // #FF00FF Magenta puro
uniform float similarity : hint_range(0.0, 1.0) = 0.35;           // Umbral de tolerancia
uniform float smoothness : hint_range(0.0, 0.5) = 0.05;           // Suavizado de bordes
uniform float despill_amount : hint_range(0.0, 1.0) = 0.6;       // Supresión de bordes rosados/halo

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Si ya es transparente, mantener
    if (tex_color.a <= 0.01) {
        COLOR = vec4(0.0);
    } else {
        // Distancia euclidiana en el espacio RGB al color clave
        float color_dist = distance(tex_color.rgb, key_color.rgb);
        
        // Calcular canal alfa basado en la similitud
        float alpha = smoothstep(similarity, similarity + smoothness, color_dist);
        
        // Supresión de color magenta residual (Despill) en bordes
        // Si el píxel tiene más rojo y azul que verde, reducir el exceso magenta
        float rb_avg = (tex_color.r + tex_color.b) * 0.5;
        float excess_magenta = max(0.0, rb_avg - tex_color.g);
        
        vec3 clean_rgb = tex_color.rgb;
        clean_rgb.r = max(0.0, clean_rgb.r - excess_magenta * despill_amount);
        clean_rgb.b = max(0.0, clean_rgb.b - excess_magenta * despill_amount);
        
        COLOR = vec4(clean_rgb, tex_color.a * alpha);
    }
}
