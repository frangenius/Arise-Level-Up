// skills.js - Clases, Habilidades y Sistema de Progresión de Atributos para LEVEL UP

// Curva de experiencia configurable en un solo lugar (Fórmula matemática)
function getXPForLevel(level) {
    if (level < 1) return 100;
    // Fórmula basada en el PDF: Nivel 1 = 100 XP, Nivel 2 = 180 XP, Nivel 3 = 280 XP, Nivel 4 = 400 XP...
    // Incremento lineal del diferencial en 20 por cada nivel
    return 100 + 10 * (level - 1) * (level + 6);
}

// Configuración de las Clases y sus bonificaciones
const CHARACTER_CLASSES = {
    guerrero: {
        id: 'guerrero',
        name: 'Guerrero',
        icon: '⚔️',
        description: 'Especialista en fuerza física y resistencia.',
        bonuses: {
            strength: 0.20, // +20% Fuerza
            defense: 0.10,  // +10% Defensa
            xpModifier: 0.0,
            goldModifier: 0.0
        },
        skills: {
            active: [
                { id: 'determinacion', name: 'Determinación', desc: 'Al fallar una misión, se pierde un 50% menos de progreso de racha.', active: true },
                { id: 'segundo_aire', name: 'Segundo Aire', desc: 'Permite recuperar 1 punto de energía semanal una vez por semana.', active: false, reqLevel: 10 }
            ],
            passive: [
                { id: 'rompe_filas', name: 'Rompefilas', desc: 'Aumenta el daño de ataque físico básico en +10.', reqLevel: 5 }
            ]
        }
    },
    estratega: {
        id: 'estratega',
        name: 'Estratega',
        icon: '🧠',
        description: 'Especialista en conocimiento, estudio y planificación.',
        bonuses: {
            intelligence: 0.20, // +20% Inteligencia
            xpModifier: 0.10,   // +10% Experiencia al completar tareas
            strength: 0.0,
            defense: 0.0,
            goldModifier: 0.0
        },
        skills: {
            active: [
                { id: 'analisis', name: 'Análisis', desc: 'Muestra información detallada sobre debilidades de los enemigos en combate.', active: true },
                { id: 'optimizacion', name: 'Optimización', desc: 'Reduce el tiempo necesario para completar misiones en un 15% (efecto cosmético de tiempo).', active: false, reqLevel: 10 }
            ],
            passive: [
                { id: 'estudio_profundo', name: 'Estudio Profundo', desc: '+15% de oro obtenido en misiones de Inteligencia.', reqLevel: 5 }
            ]
        }
    },
    desafiante: {
        id: 'desafiante',
        name: 'Desafiante',
        icon: '🔥',
        description: 'Especialista en superar límites y mantener la constancia.',
        bonuses: {
            spirit: 0.20,      // +20% Espíritu
            goldModifier: 0.15, // +15% de Oro
            strength: 0.0,
            defense: 0.0,
            xpModifier: 0.0
        },
        skills: {
            active: [
                { id: 'superacion', name: 'Superación', desc: 'Al completar una misión extrema, recibe un +50% de XP adicional.', active: true },
                { id: 'voluntad', name: 'Voluntad', desc: 'Protege la racha actual ante un fallo ocasional (una vez cada 3 días).', active: false, reqLevel: 10 }
            ],
            passive: [
                { id: 'foco_total', name: 'Enfoque Total', desc: 'Reduce el impacto de la decadencia temporal en misiones.', reqLevel: 5 }
            ]
        }
    },
    explorador: {
        id: 'explorador',
        name: 'Explorador',
        icon: '⚡',
        description: 'Especialista en adaptación, descubrimiento y variedad.',
        bonuses: {
            speed: 0.15, // Afectará al orden de turno en combates
            xpModifier: 0.05,
            goldModifier: 0.05,
            strength: 0.0,
            defense: 0.0
        },
        skills: {
            active: [
                { id: 'adaptacion', name: 'Adaptación', desc: 'Permite cambiar las recompensas recomendadas de una misión una vez al día.', active: true },
                { id: 'descubrimiento', name: 'Descubrimiento', desc: '+25% de probabilidad de encontrar materiales raros en los cofres de loot.', active: false, reqLevel: 10 }
            ],
            passive: [
                { id: 'paso_ligero', name: 'Paso Ligero', desc: 'Otorga esquiva de ataques enemigos en portales (+5% probabilidad de fallo del enemigo).', reqLevel: 5 }
            ]
        }
    }
};

// Rangos de Cazador y sus requisitos
const HUNTER_RANGS = [
    { rank: 'E', name: 'Cazador Rango E', bg: 'dark_forest', desc: 'Usuario inicial. Bienvenido al Sistema.', reqLevel: 1, reqMissions: 0, reqDays: 0 },
    { rank: 'D', name: 'Cazador Rango D', bg: 'ruins', desc: 'Primer progreso. Tu fuerza comienza a despertar.', reqLevel: 10, reqMissions: 50, reqDays: 0 },
    { rank: 'C', name: 'Cazador Rango C', bg: 'mountains', desc: 'Usuario constante. Has demostrado disciplina.', reqLevel: 30, reqMissions: 200, reqDays: 30 },
    { rank: 'B', name: 'Cazador Rango B', bg: 'temple', desc: 'Usuario avanzado. Eres un guerrero respetado.', reqLevel: 75, reqMissions: 500, reqDays: 60 },
    { rank: 'A', name: 'Cazador Rango A', bg: 'destroyed_city', desc: 'Usuario élite. Pocos logran este nivel de constancia.', reqLevel: 150, reqMissions: 1000, reqDays: 120 },
    { rank: 'S', name: 'Cazador Rango S', bg: 'blue_dimension', desc: 'Usuario excepcional. Dominas el Sistema por completo.', reqLevel: 300, reqMissions: 2000, reqDays: 240 },
    { rank: 'SS', name: 'Rango SS', bg: 'cosmic_void', desc: 'Leyenda viviente. El poder del Sistema fluye sin límites.', reqLevel: 500, reqMissions: 4000, reqDays: 365 },
    { rank: 'SSS', name: 'Rango SSS', bg: 'monarch_hall', desc: 'Nivel semidios. La constancia absoluta personificada.', reqLevel: 750, reqMissions: 6000, reqDays: 500 },
    { rank: 'National Hunter', name: 'Cazador Nacional', bg: 'golden_city', desc: 'Uno de los pilares de la humanidad.', reqLevel: 1000, reqMissions: 8000, reqDays: 730 },
    { rank: 'Monarch', name: 'Monarca', bg: 'shadow_monarch', desc: 'El gobernante supremo del Sistema. Nivel absoluto.', reqLevel: 1500, reqMissions: 12000, reqDays: 1000 }
];

// Calcular rango basado en nivel, misiones completadas y días activos
function calculateRank(level, completedMissionsCount, daysActive) {
    let currentRank = HUNTER_RANGS[0];
    for (const rankInfo of HUNTER_RANGS) {
        if (level >= rankInfo.reqLevel && completedMissionsCount >= rankInfo.reqMissions && daysActive >= rankInfo.reqDays) {
            currentRank = rankInfo;
        } else {
            break; // No cumple con los requisitos del rango superior
        }
    }
    return currentRank;
}

// Calcular Poder de Ataque (AP)
function calculateAttackPower(stats, userClass, equippedItems, activeCompanions, activeTitleBonus) {
    // AP = Strength + Defense + Bonificaciones de Clase + Bonificación de Arma + Compañero + Títulos
    const baseStr = stats.strength.current;
    const baseDef = stats.defense.current;

    let classBonusStr = 0;
    let classBonusDef = 0;

    if (userClass && CHARACTER_CLASSES[userClass]) {
        const cls = CHARACTER_CLASSES[userClass];
        classBonusStr = baseStr * (cls.bonuses.strength || 0);
        classBonusDef = baseDef * (cls.bonuses.defense || 0);
    }

    let weaponBonus = 0;
    let armorBonus = 0;

    equippedItems.forEach(item => {
        if (item.type === 'arma') {
            weaponBonus += (item.stats.attack || 0) + ((item.stats.upgradeLevel || 0) * 5); // +5 ataque por nivel de mejora
        }
        if (item.type === 'armadura') {
            armorBonus += (item.stats.defense || 0) + ((item.stats.upgradeLevel || 0) * 3); // +3 defensa por nivel de mejora
        }
    });

    let companionBonus = 0;
    activeCompanions.forEach(companion => {
        if (companion.stats && companion.stats.attack) {
            companionBonus += companion.stats.attack;
        }
        if (companion.stats && companion.stats.defense) {
            armorBonus += companion.stats.defense; // Añadir a defensa
        }
    });

    let titleBonus = activeTitleBonus || 0;

    // Cálculo final de AP
    const totalStr = baseStr + classBonusStr + weaponBonus;
    const totalDef = baseDef + classBonusDef + armorBonus;

    const ap = Math.round(totalStr + totalDef + companionBonus + titleBonus);
    return {
        ap,
        details: {
            strength: Math.round(totalStr),
            defense: Math.round(totalDef),
            weaponBonus,
            armorBonus,
            companionBonus,
            titleBonus
        }
    };
}

// Lista de Títulos desbloqueables
const UNLOCKABLE_TITLES = [
    { id: 'principiante', name: 'Principiante', desc: 'Acaba de recibir acceso al Sistema.', bonus: 2, condition: 'Primer inicio' },
    { id: 'veterano', name: 'Veterano', desc: 'Otorga +5 AP. Requiere nivel 25.', bonus: 5, condition: 'Alcanzar Nivel 25' },
    { id: 'inquebrantable', name: 'Inquebrantable', desc: 'Otorga +10 AP. Completa 100 misiones sin fallar.', bonus: 10, condition: '100 misiones completadas' },
    { id: 'maestro_conocimiento', name: 'Maestro del Conocimiento', desc: 'Otorga +5 Inteligencia pasiva. Dedica 100 horas de estudio.', bonus: 5, condition: '100 horas de estudio' },
    { id: 'cazador_nocturno', name: 'Cazador Nocturno', desc: 'Otorga +8 AP. Completa una misión después de las 22:00.', bonus: 8, condition: 'Misión nocturna' },
    { id: 'rey_rachas', name: 'Rey de las Rachas', desc: 'Otorga +15 AP. Mantén una racha de 30 días.', bonus: 15, condition: 'Racha de 30 días' },
    { id: 'coleccionista', name: 'Coleccionista', desc: 'Otorga +10 AP. Obtén 50 objetos diferentes en el inventario.', bonus: 10, condition: '50 objetos coleccionados' },
    { id: 'dragon_slayer', name: 'Dragon Slayer', desc: 'Otorga +30 AP. Derrota al Dragón Azul en el Portal S.', bonus: 30, condition: 'Derrotar Dragón Azul' },
    { id: 'legendario', name: 'Legendario', desc: 'Otorga +50 AP. Alcanza el nivel 100.', bonus: 50, condition: 'Alcanzar Nivel 100' }
];

window.getXPForLevel = getXPForLevel;
window.CHARACTER_CLASSES = CHARACTER_CLASSES;
window.HUNTER_RANGS = HUNTER_RANGS;
window.calculateRank = calculateRank;
window.calculateAttackPower = calculateAttackPower;
window.UNLOCKABLE_TITLES = UNLOCKABLE_TITLES;
console.log('Skills logic (skills.js) cargado correctamente.');
