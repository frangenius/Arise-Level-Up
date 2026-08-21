// missions.js - Gestión de Misiones y Temporizador de Concentración (Modo Enfoque)

// Misiones predefinidas por atributo
const MISSION_PRESETS = {
    strength: [
        { name: 'Flexiones', desc: 'Realiza flexiones de brazos.', duration: 15, difficulty: 'facil', reward_xp: 30, reward_gold: 20 },
        { name: 'Sentadillas', desc: 'Realiza sentadillas libres.', duration: 15, difficulty: 'facil', reward_xp: 30, reward_gold: 20 },
        { name: 'Salir a correr', desc: 'Entrenamiento de carrera cardiovascular.', duration: 30, difficulty: 'normal', reward_xp: 60, reward_gold: 50 },
        { name: 'Levantamiento de Pesas', desc: 'Entrenamiento de fuerza en gimnasio o casa.', duration: 45, difficulty: 'dificil', reward_xp: 100, reward_gold: 80 },
        { name: 'Caminata enérgica', desc: 'Caminar a paso rápido al aire libre.', duration: 20, difficulty: 'muy_facil', reward_xp: 15, reward_gold: 10 }
    ],
    intelligence: [
        { name: 'Leer un libro', desc: 'Lectura concentrada sin distracciones.', duration: 30, difficulty: 'normal', reward_xp: 50, reward_gold: 40 },
        { name: 'Estudiar teoría', desc: 'Sesión de estudio enfocado en material académico.', duration: 45, difficulty: 'dificil', reward_xp: 90, reward_gold: 70 },
        { name: 'Programar código', desc: 'Desarrollar software o resolver problemas de código.', duration: 60, difficulty: 'extrema', reward_xp: 150, reward_gold: 120 },
        { name: 'Aprender Idiomas', desc: 'Práctica y vocabulario de un idioma extranjero.', duration: 20, difficulty: 'facil', reward_xp: 30, reward_gold: 25 },
        { name: 'Resolver Matemáticas', desc: 'Ejercicios de lógica o cálculo mental.', duration: 25, difficulty: 'normal', reward_xp: 45, reward_gold: 35 }
    ],
    discipline: [
        { name: 'Ordenar habitación', desc: 'Organizar y limpiar el entorno personal.', duration: 15, difficulty: 'muy_facil', reward_xp: 20, reward_gold: 15 },
        { name: 'Bloqueo de redes sociales', desc: 'Periodo de desintoxicación digital activa.', duration: 60, difficulty: 'dificil', reward_xp: 80, reward_gold: 90 },
        { name: 'Cumplir horario estricto', desc: 'Ejecutar tareas según lo planificado.', duration: 45, difficulty: 'normal', reward_xp: 60, reward_gold: 50 },
        { name: 'Levantarse temprano', desc: 'Levantarse inmediatamente al sonar la alarma (comprobación).', duration: 10, difficulty: 'facil', reward_xp: 25, reward_gold: 20 }
    ],
    spirit: [
        { name: 'Meditación profunda', desc: 'Meditar en silencio controlando la respiración.', duration: 15, difficulty: 'facil', reward_xp: 30, reward_gold: 25 },
        { name: 'Escribir un diario (Journaling)', desc: 'Registrar pensamientos y agradecimientos del día.', duration: 15, difficulty: 'muy_facil', reward_xp: 15, reward_gold: 15 },
        { name: 'Ejercicios de respiración', desc: 'Práctica de respiración diafragmática consciente.', duration: 10, difficulty: 'muy_facil', reward_xp: 15, reward_gold: 10 },
        { name: 'Estiramientos / Yoga', desc: 'Sesión de relajación y estiramiento corporal.', duration: 20, difficulty: 'facil', reward_xp: 30, reward_gold: 30 }
    ],
    defense: [
        { name: 'Hidratación constante', desc: 'Tomar 2 litros de agua durante el día (registro).', duration: 5, difficulty: 'muy_facil', reward_xp: 15, reward_gold: 15 },
        { name: 'Comer saludable', desc: 'Evitar alimentos ultraprocesados y preferir verduras.', duration: 10, difficulty: 'facil', reward_xp: 25, reward_gold: 20 },
        { name: 'Evitar comida chatarra', desc: 'Día completo sin azúcares ni grasas saturadas.', duration: 30, difficulty: 'normal', reward_xp: 50, reward_gold: 45 },
        { name: 'Estirar antes de dormir', desc: 'Rutina corta de estiramientos para relajar músculos.', duration: 10, difficulty: 'muy_facil', reward_xp: 15, reward_gold: 15 }
    ]
};

// Misiones Especiales / Mini Tareas (Eventos especiales no generados por el usuario: 1 por día)
const MINI_TASKS_PRESETS = [
    { name: '💪 Hacer 10 flexiones', desc: 'Realiza 10 flexiones de brazos para mantener la fuerza.', attribute: 'strength', reward_xp: 20, reward_gold: 15 },
    { name: '📖 Leer +15 minutos', desc: 'Lectura concentrada durante al menos 15 minutos.', attribute: 'intelligence', reward_xp: 25, reward_gold: 20 },
    { name: '✍️ Estudiar +15 minutos', desc: 'Sesión de estudio o práctica enfocada de 15 minutos.', attribute: 'intelligence', reward_xp: 25, reward_gold: 20 }
];

// Generar misión especial diaria (1 por día)
function generateMiniTasks(count = 1, excludeNames = []) {
    const available = MINI_TASKS_PRESETS.filter(p => !excludeNames.includes(p.name));
    const pool = available.length >= count ? available : MINI_TASKS_PRESETS;
    const shuffled = [...pool].sort(() => 0.5 - Math.random());
    const selected = shuffled.slice(0, count);

    return selected.map(preset => ({
        name: preset.name,
        desc: preset.desc,
        type: 'mini', // mini tarea sin timer
        difficulty: 'muy_facil',
        duration: 0, // 0 minutos = sin timer
        reward_xp: preset.reward_xp,
        reward_gold: preset.reward_gold,
        attribute: preset.attribute,
        completed: false,
        time_spent: 0,
        date_created: new Date().toISOString().split('T')[0]
    }));
}

// Generar misiones diarias iniciales recomendadas según el perfil de calibración o plantillas de rutina
function generateDailyMissions(routineTemplatesOrGoal, level = 1) {
    const list = [];
    const todayStr = new Date().toISOString().split('T')[0];

    // Si se pasan plantillas configuradas por el usuario (Array de templates de rutina)
    if (Array.isArray(routineTemplatesOrGoal) && routineTemplatesOrGoal.length > 0) {
        routineTemplatesOrGoal.forEach(t => {
            const multiplier = 1 + (level - 1) * 0.03;
            let finalXp = Math.round((t.reward_xp || 30) * multiplier);
            let finalGold = Math.round((t.reward_gold || 20) * multiplier);

            list.push({
                name: t.name,
                desc: t.desc || 'Misión de rutina diaria fija.',
                type: 'diaria',
                difficulty: t.difficulty || 'normal',
                duration: t.duration || 15,
                reward_xp: finalXp,
                reward_gold: finalGold,
                attribute: t.attribute || 'discipline',
                completed: false,
                time_spent: 0,
                date_created: todayStr,
                templateId: t.id
            });
        });
        return list;
    }

    const mainGoal = typeof routineTemplatesOrGoal === 'string' ? routineTemplatesOrGoal : 'fisico';
    const attributes = ['strength', 'intelligence', 'discipline', 'spirit', 'defense'];
    
    // Prioridad según el objetivo principal del usuario
    let primaryAttr = 'discipline';
    if (mainGoal === 'fisico') primaryAttr = 'strength';
    else if (mainGoal === 'aprender') primaryAttr = 'intelligence';
    else if (mainGoal === 'bienestar') primaryAttr = 'spirit';
    else if (mainGoal === 'habitos') primaryAttr = 'defense';

    // 1. Misión prioritaria del objetivo (Preset Normal o Fácil)
    const primaryPresets = MISSION_PRESETS[primaryAttr];
    const pPreset = primaryPresets[Math.floor(Math.random() * primaryPresets.length)];
    list.push(createMissionInstance(pPreset, primaryAttr, 'diaria', level));

    // 2. Dos misiones de otros atributos al azar (Fáciles o Normales)
    let remainingAttrs = attributes.filter(a => a !== primaryAttr);
    for (let i = 0; i < 2; i++) {
        const randIdx = Math.floor(Math.random() * remainingAttrs.length);
        const attr = remainingAttrs[randIdx];
        remainingAttrs.splice(randIdx, 1); // Evitar repetido

        const presets = MISSION_PRESETS[attr];
        const preset = presets[Math.floor(Math.random() * presets.length)];
        list.push(createMissionInstance(preset, attr, 'diaria', level));
    }

    // 3. Una misión de disciplina común (Muy Fácil o Fácil)
    const discPresets = MISSION_PRESETS['discipline'].filter(p => p.difficulty === 'muy_facil' || p.difficulty === 'facil');
    const dPreset = discPresets[Math.floor(Math.random() * discPresets.length)];
    list.push(createMissionInstance(dPreset, 'discipline', 'diaria', level));

    return list;
}

// Convertir un preset a una instancia de misión con ID y estados
function createMissionInstance(preset, attribute, type = 'diaria', level = 1) {
    // Escalamiento automático según el nivel del usuario
    const multiplier = 1 + (level - 1) * 0.03; // +3% exigencia/recompensa por nivel
    
    // Dificultad escalada (solo si el escalado automático está activado)
    let finalDuration = preset.duration;
    let finalXp = Math.round(preset.reward_xp * multiplier);
    let finalGold = Math.round(preset.reward_gold * multiplier);

    return {
        name: preset.name,
        desc: preset.desc,
        type: type, // 'diaria', 'semanal', 'especial', 'personalizada', 'mini'
        difficulty: preset.difficulty, // 'muy_facil', 'facil', 'normal', 'dificil', 'extrema'
        duration: finalDuration, // minutos
        reward_xp: finalXp,
        reward_gold: finalGold,
        attribute: attribute,
        completed: false,
        time_spent: 0,
        date_created: new Date().toISOString().split('T')[0]
    };
}

// Lógica de Temporizador de Enfoque
let timerInterval = null;
let timerSecondsLeft = 0;
let totalTimerSeconds = 0;
let activeMission = null;
let focusStartTime = 0;

function startFocusTimer(mission, onTick, onComplete, onCancel) {
    if (timerInterval) clearInterval(timerInterval);

    activeMission = mission;
    totalTimerSeconds = mission.duration * 60; // Convertir minutos a segundos
    timerSecondsLeft = totalTimerSeconds;
    focusStartTime = Date.now();

    // Registro anti-trampa al iniciar
    const antiCheatLog = {
        missionId: mission.id,
        startTime: focusStartTime,
        declaredDuration: totalTimerSeconds,
        state: 'running'
    };
    localStorage.setItem('active_focus_session', JSON.stringify(antiCheatLog));

    onTick(timerSecondsLeft, totalTimerSeconds);

    timerInterval = setInterval(() => {
        timerSecondsLeft--;
        onTick(timerSecondsLeft, totalTimerSeconds);

        if (timerSecondsLeft <= 0) {
            clearInterval(timerInterval);
            timerInterval = null;
            localStorage.removeItem('active_focus_session');
            onComplete(activeMission);
        }
    }, 1000);

    // Sistema Anti-trampa: Escuchar cuando el usuario sale de la aplicación (cambio de pestaña)
    const handleVisibilityChange = () => {
        if (document.hidden && timerInterval) {
            console.warn('Se detectó que el usuario salió de la aplicación durante la misión.');
            // Podemos pausar, o alertar. Para este MVP mostraremos advertencia al regresar
        }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);

    // Retornar función para detener/desregistrar eventos
    return {
        stop: () => {
            if (timerInterval) {
                clearInterval(timerInterval);
                timerInterval = null;
            }
            document.removeEventListener('visibilitychange', handleVisibilityChange);
        }
    };
}

// Cancelar misión activa y aplicar penalización
function cancelFocusTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
    localStorage.removeItem('active_focus_session');

    const mission = activeMission;
    activeMission = null;
    return mission; // Retorna la misión que falló
}

// Activar Modo de Recuperación ante inactividad larga
function checkRecoveryMode(lastLoginDate) {
    if (!lastLoginDate) return null;
    
    const today = new Date();
    const lastLogin = new Date(lastLoginDate);
    const diffTime = Math.abs(today - lastLogin);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    // Si pasaron 3 o más días sin abrir la aplicación, se activa la misión especial de recuperación
    if (diffDays >= 3) {
        return {
            name: 'Regreso del Hunter',
            desc: 'Has estado inactivo. Tu fuerza ha decaído. Completa esta misión de reintroducción para restaurar tu ritmo.',
            type: 'especial',
            difficulty: 'normal',
            duration: 20, // 20 minutos
            reward_xp: 150,
            reward_gold: 100,
            attribute: 'discipline',
            is_recovery: true,
            completed: false,
            time_spent: 0,
            date_created: new Date().toISOString().split('T')[0]
        };
    }
    return null;
}

window.MISSION_PRESETS = MISSION_PRESETS;
window.MINI_TASKS_PRESETS = MINI_TASKS_PRESETS;
window.generateMiniTasks = generateMiniTasks;
window.generateDailyMissions = generateDailyMissions;
window.createMissionInstance = createMissionInstance;
window.startFocusTimer = startFocusTimer;
window.cancelFocusTimer = cancelFocusTimer;
window.checkRecoveryMode = checkRecoveryMode;
console.log('Missions manager (missions.js) cargado correctamente.');
