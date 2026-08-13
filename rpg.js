// rpg.js - Sistema RPG, Combate por Turnos, Portales, Crafting e Inventario

// Tipos de Portales
const PORTALS_CONFIG = [
    { rank: 'E', name: 'Portal de Iniciación (Rango E)', energyCost: 1, battlesCount: 3, enemies: ['slime', 'goblin', 'lobo'], boss: 'slime_gigante', desc: 'Ideal para cazadores novatos. Enemigos débiles.', minLevel: 1 },
    { rank: 'D', name: 'Mazmorra de Ruinas (Rango D)', energyCost: 1, battlesCount: 4, enemies: ['goblin', 'lobo', 'esqueleto', 'arana'], boss: 'arana_reina', desc: 'Primer desafío real. Cuidado con el veneno.', minLevel: 10 },
    { rank: 'C', name: 'Montañas Heladas (Rango C)', energyCost: 1, battlesCount: 5, enemies: ['esqueleto', 'arana', 'orco', 'zombie'], boss: 'lich', desc: 'Enemigos con estados alterados (congelación y parálisis).', minLevel: 30 },
    { rank: 'B', name: 'Templo de Criptas (Rango B)', energyCost: 1, battlesCount: 6, enemies: ['zombie', 'orco', 'mimo', 'caballero_maldito'], boss: 'rey_goblin', desc: 'Gran cantidad de enemigos y mini-jefes.', minLevel: 75 },
    { rank: 'A', name: 'Ciudad Destruida (Rango A)', energyCost: 1, battlesCount: 8, enemies: ['caballero_maldito', 'golem', 'vampiro', 'quimera'], boss: 'golem_ancestral', desc: 'Combates múltiples. Requiere alta preparación física y mental.', minLevel: 150 },
    { rank: 'S', name: 'Dimensión Azul (Rango S)', energyCost: 1, battlesCount: 10, enemies: ['quimera', 'vampiro', 'espectro_oscuro', 'soldado_sombra'], boss: 'dragon_azul', desc: 'Jefe extremadamente difícil. Grandes recompensas de rango legendario.', minLevel: 300 }
];

// Bestiario y estadísticas base de enemigos
const BESTIARY = {
    slime: { name: 'Slime', icon: '🟢', hp: 40, attack: 8, defense: 2, xp: 20, gold: 15, loot: [{ item: 'esencia_magica', chance: 0.5 }] },
    goblin: { name: 'Goblin', icon: '👺', hp: 60, attack: 12, defense: 4, xp: 35, gold: 25, loot: [{ item: 'cuero', chance: 0.4 }, { item: 'colmillo', chance: 0.2 }] },
    lobo: { name: 'Lobo de Colmillos', icon: '🐺', hp: 80, attack: 16, defense: 6, xp: 50, gold: 35, loot: [{ item: 'piel_lobo', chance: 0.6 }, { item: 'garra', chance: 0.3 }] },
    esqueleto: { name: 'Guerrero Esqueleto', icon: '💀', hp: 100, attack: 20, defense: 10, xp: 70, gold: 50, loot: [{ item: 'hierro', chance: 0.5 }, { item: 'fragmento_oscuro', chance: 0.15 }] },
    arana: { name: 'Araña de las Sombras', icon: '🕷️', hp: 90, attack: 22, defense: 8, xp: 75, gold: 55, statusEffect: 'veneno', loot: [{ item: 'garra', chance: 0.5 }] },
    orco: { name: 'Guerrero Orco', icon: '🐗', hp: 150, attack: 30, defense: 15, xp: 120, gold: 80, loot: [{ item: 'hierro', chance: 0.6 }, { item: 'cuero', chance: 0.5 }] },
    zombie: { name: 'Caminante Infectado', icon: '🧟', hp: 120, attack: 25, defense: 12, xp: 100, gold: 70, statusEffect: 'debilidad', loot: [{ item: 'esencia_magica', chance: 0.4 }] },
    mimo: { name: 'Cofre Trampa (Mimo)', icon: '📦', hp: 140, attack: 35, defense: 20, xp: 200, gold: 200, loot: [{ item: 'cristal_azul', chance: 0.8 }, { item: 'piedra_runica', chance: 0.3 }] },
    caballero_maldito: { name: 'Caballero Maldito', icon: '🛡️', hp: 200, attack: 40, defense: 30, xp: 300, gold: 150, special: 'contraataque', loot: [{ item: 'hierro', chance: 0.8 }, { item: 'fragmento_oscuro', chance: 0.4 }] },
    golem: { name: 'Golem de Piedra', icon: '🗿', hp: 300, attack: 35, defense: 45, xp: 400, gold: 180, loot: [{ item: 'madera_antigua', chance: 0.6 }, { item: 'cristal_azul', chance: 0.5 }] },
    vampiro: { name: 'Vampiro Noble', icon: '🧛', hp: 220, attack: 50, defense: 22, xp: 450, gold: 250, statusEffect: 'sangrado', loot: [{ item: 'esencia_magica', chance: 0.7 }, { item: 'pluma_fenix', chance: 0.2 }] },
    quimera: { name: 'Quimera de Fuego', icon: '🦁', hp: 280, attack: 55, defense: 28, xp: 500, gold: 300, statusEffect: 'quemadura', loot: [{ item: 'colmillo', chance: 0.6 }, { item: 'garra', chance: 0.6 }] },
    espectro_oscuro: { name: 'Espectro de Sombra', icon: '👻', hp: 240, attack: 60, defense: 25, xp: 600, gold: 350, statusEffect: 'aturdimiento', loot: [{ item: 'fragmento_oscuro', chance: 0.8 }, { item: 'nucleo_mana', chance: 0.2 }] },
    soldado_sombra: { name: 'Soldado de las Sombras', icon: '👥', hp: 350, attack: 70, defense: 40, xp: 800, gold: 400, loot: [{ item: 'nucleo_mana', chance: 0.5 }, { item: 'piedra_runica', chance: 0.4 }] },
    
    // Jefes Finales
    slime_gigante: { name: 'Rey Slime (Jefe)', icon: '👑🟢', hp: 120, attack: 15, defense: 5, xp: 100, gold: 100, isBoss: true, loot: [{ item: 'receta_espada_acero', chance: 1.0 }, { item: 'esencia_magica', chance: 1.0 }] },
    arana_reina: { name: 'Reina de las Arañas (Jefe)', icon: '👑🕷️', hp: 250, attack: 35, defense: 18, xp: 300, gold: 250, isBoss: true, statusEffect: 'veneno', loot: [{ item: 'receta_armadura_cuero', chance: 1.0 }, { item: 'colmillo', chance: 1.0 }] },
    lich: { name: 'El Liche (Jefe)', icon: '🧙‍♂️💀', hp: 500, attack: 55, defense: 25, xp: 800, gold: 500, isBoss: true, statusEffect: 'paralisis', loot: [{ item: 'receta_espada_plata', chance: 1.0 }, { item: 'nucleo_mana', chance: 1.0 }] },
    rey_goblin: { name: 'Rey Goblin (Jefe)', icon: '👑👺', hp: 800, attack: 75, defense: 40, xp: 1500, gold: 1000, isBoss: true, special: 'invoca_aliados', loot: [{ item: 'receta_pechera_hierro', chance: 1.0 }, { item: 'cristal_azul', chance: 1.0 }] },
    golem_ancestral: { name: 'Golem Ancestral (Jefe)', icon: '🗿🔥', hp: 1500, attack: 100, defense: 80, xp: 3000, gold: 2000, isBoss: true, special: 'terremoto', loot: [{ item: 'receta_espada_cazador', chance: 1.0 }, { item: 'piedra_runica', chance: 1.0 }] },
    dragon_azul: { name: 'Dragón Azul de la Tempestad (Jefe)', icon: '🐉⚡', hp: 3000, attack: 160, defense: 120, xp: 10000, gold: 5000, isBoss: true, statusEffect: 'quemadura', loot: [{ item: 'corona_primer_hunter', chance: 0.1 }, { item: 'pluma_fenix', chance: 1.0 }, { item: 'nucleo_mana', chance: 1.0 }] }
};

// Configuración de Objetos
const ITEMS_DATABASE = {
    // Materiales de forja
    cuero: { id: 'cuero', name: 'Cuero Común', type: 'material', rarity: 'comun', icon: '🎒', desc: 'Piel curtida simple.' },
    piel_lobo: { id: 'piel_lobo', name: 'Piel de Lobo', type: 'material', rarity: 'poco_comun', icon: '🐺', desc: 'Piel gruesa y abrigada.' },
    hierro: { id: 'hierro', name: 'Mineral de Hierro', type: 'material', rarity: 'comun', icon: '🔩', desc: 'Metal básico para forja.' },
    madera_antigua: { id: 'madera_antigua', name: 'Madera Antigua', type: 'material', rarity: 'comun', icon: '🪵', desc: 'Madera densa de bosques mágicos.' },
    colmillo: { id: 'colmillo', name: 'Colmillo Afilado', type: 'material', rarity: 'poco_comun', icon: '🦷', desc: 'Colmillo de bestia salvaje.' },
    garra: { id: 'garra', name: 'Garra Desgarradora', type: 'material', rarity: 'poco_comun', icon: '💅', desc: 'Garra afilada útil para forja.' },
    cristal_azul: { id: 'cristal_azul', name: 'Cristal de Maná Azul', type: 'material', rarity: 'raro', icon: '💎', desc: 'Cristal infundido con energía mágica.' },
    fragmento_oscuro: { id: 'fragmento_oscuro', name: 'Fragmento de Sombra', type: 'material', rarity: 'raro', icon: '🖤', desc: 'Material misterioso de los portales.' },
    esencia_magica: { id: 'esencia_magica', name: 'Esencia Mágica', type: 'material', rarity: 'poco_comun', icon: '🧪', desc: 'Polvo brillante con propiedades curativas.' },
    nucleo_mana: { id: 'nucleo_mana', name: 'Núcleo de Maná', type: 'material', rarity: 'epico', icon: '🟣', desc: 'Núcleo concentrado de un jefe.' },
    pluma_fenix: { id: 'pluma_fenix', name: 'Pluma de Fénix', type: 'material', rarity: 'legendario', icon: '🪶', desc: 'Pluma ardiente capaz de restaurar vida.' },
    piedra_runica: { id: 'piedra_runica', name: 'Piedra Rúnica', type: 'material', rarity: 'epico', icon: '🪨', desc: 'Piedra grabada con runas antiguas de poder.' },

    // Consumibles para Combate
    pocion_peque: { id: 'pocion_peque', name: 'Poción Pequeña', type: 'consumible', rarity: 'comun', icon: '🧪', desc: 'Recupera 50 HP durante el combate.', effect: { type: 'heal', value: 50 } },
    pocion_grande: { id: 'pocion_grande', name: 'Poción Grande', type: 'consumible', rarity: 'raro', icon: '🧪', desc: 'Recupera 150 HP durante el combate.', effect: { type: 'heal', value: 150 } },
    antidoto: { id: 'antidoto', name: 'Antídoto', type: 'consumible', rarity: 'comun', icon: '💊', desc: 'Cura los estados de Veneno y Sangrado.', effect: { type: 'cleanse' } },
    bomba_fuego: { id: 'bomba_fuego', name: 'Bomba de Fuego', type: 'consumible', rarity: 'poco_comun', icon: '💣', desc: 'Aplica 40 de daño y estado Quemadura.', effect: { type: 'damage_effect', value: 40, status: 'quemadura' } },
    cristal_helado: { id: 'cristal_helado', name: 'Cristal Helado', type: 'consumible', rarity: 'raro', icon: '❄️', desc: 'Aplica 60 de daño y estado Congelación.', effect: { type: 'damage_effect', value: 60, status: 'congelacion' } },
    pergamino_electrico: { id: 'pergamino_electrico', name: 'Pergamino Eléctrico', type: 'consumible', rarity: 'raro', icon: '📜', desc: 'Aplica 80 de daño y estado Parálisis.', effect: { type: 'damage_effect', value: 80, status: 'paralisis' } },

    // Equipamiento (Armas)
    espada_entrenamiento: { id: 'espada_entrenamiento', name: 'Espada de Madera', type: 'arma', rarity: 'comun', icon: '🪵🗡️', desc: 'Arma simple de práctica.', stats: { attack: 10, upgradeLevel: 0 } },
    espada_acero: { id: 'espada_acero', name: 'Espada de Acero', type: 'arma', rarity: 'poco_comun', icon: '🗡️', desc: 'Espada de metal bien forjada.', stats: { attack: 25, upgradeLevel: 0 } },
    espada_plata: { id: 'espada_plata', name: 'Espada de Plata', type: 'arma', rarity: 'raro', icon: '⚔️', desc: 'Efectiva contra monstruos mágicos. Aplica Sangrado.', stats: { attack: 50, effect: 'sangrado', upgradeLevel: 0 } },
    espada_cazador: { id: 'espada_cazador', name: 'Espada de Cazador', type: 'arma', rarity: 'epico', icon: '🔱', desc: 'Fuerza imbuida por el Sistema. Aumenta Crítico.', stats: { attack: 95, critChance: 0.15, upgradeLevel: 0 } },
    daga_sombras: { id: 'daga_sombras', name: 'Daga de las Sombras', type: 'arma', rarity: 'legendario', icon: '🗡️🖤', desc: 'Arma letal de asesino. Muy veloz y gran daño crítico.', stats: { attack: 140, critChance: 0.25, upgradeLevel: 0 } },
    espada_monarca: { id: 'espada_monarca', name: 'Espada del Monarca de las Sombras', type: 'arma', rarity: 'mitico', icon: '🔮', desc: 'El arma definitiva del soberano. Poder absoluto.', stats: { attack: 280, critChance: 0.35, upgradeLevel: 0 } },

    // Equipamiento (Armaduras / Pecheras)
    armadura_entrenamiento: { id: 'armadura_entrenamiento', name: 'Ropa Deportiva', type: 'armadura', rarity: 'comun', icon: '👕', desc: 'Cómoda pero no protege mucho.', stats: { defense: 5, upgradeLevel: 0 } },
    armadura_cuero: { id: 'armadura_cuero', name: 'Peto de Cuero', type: 'armadura', rarity: 'poco_comun', icon: '🧥', desc: 'Armadura ligera de cuero de bestia.', stats: { defense: 15, upgradeLevel: 0 } },
    pechera_hierro: { id: 'pechera_hierro', name: 'Pechera de Hierro', type: 'armadura', rarity: 'raro', icon: '🛡️', desc: 'Defensa pesada de metal.', stats: { defense: 35, upgradeLevel: 0 } },
    cota_malla_sombra: { id: 'cota_malla_sombra', name: 'Malla de la Sombra', type: 'armadura', rarity: 'epico', icon: '🥋', desc: 'Ligera pero increíblemente resistente.', stats: { defense: 65, dodgeChance: 0.08, upgradeLevel: 0 } },
    armadura_monarca: { id: 'armadura_monarca', name: 'Armadura Monarca', type: 'armadura', rarity: 'mitico', icon: '🌌', desc: 'Te envuelve en la oscuridad del abismo protegiendo tu vida.', stats: { defense: 180, dodgeChance: 0.15, upgradeLevel: 0 } },

    // Recetas de Forja
    receta_espada_acero: { id: 'receta_espada_acero', name: 'Receta: Espada de Acero', type: 'receta', rarity: 'poco_comun', icon: '📜', desc: 'Desbloquea la fabricación de la Espada de Acero.', recipe: { target: 'espada_acero', materials: { hierro: 8, cuero: 2 }, gold: 150 } },
    receta_armadura_cuero: { id: 'receta_armadura_cuero', name: 'Receta: Peto de Cuero', type: 'receta', rarity: 'poco_comun', icon: '📜', desc: 'Desbloquea la fabricación del Peto de Cuero.', recipe: { target: 'armadura_cuero', materials: { cuero: 8, piel_lobo: 2 }, gold: 150 } },
    receta_espada_plata: { id: 'receta_espada_plata', name: 'Receta: Espada de Plata', type: 'receta', rarity: 'raro', icon: '📜', desc: 'Desbloquea la fabricación de la Espada de Plata.', recipe: { target: 'espada_plata', materials: { hierro: 12, esencia_magica: 5, colmillo: 4 }, gold: 400 } },
    receta_pechera_hierro: { id: 'receta_pechera_hierro', name: 'Receta: Pechera de Hierro', type: 'receta', rarity: 'raro', icon: '📜', desc: 'Desbloquea la fabricación de la Pechera de Hierro.', recipe: { target: 'pechera_hierro', materials: { hierro: 20, cuero: 6, garra: 4 }, gold: 500 } },
    receta_espada_cazador: { id: 'receta_espada_cazador', name: 'Receta: Espada de Cazador', type: 'receta', rarity: 'epico', icon: '📜', desc: 'Desbloquea la fabricación de la Espada de Cazador.', recipe: { target: 'espada_cazador', materials: { hierro: 30, cristal_azul: 5, nucleo_mana: 1 }, gold: 1200 } },

    // Compañeros
    lobo_companero: { id: 'lobo_companero', name: 'Lobo de Sombra (Compañero)', type: 'companero', rarity: 'raro', icon: '🐺', desc: 'Otorga +5% XP pasiva en misiones y +10 de ataque en combates.', stats: { attack: 10, xpBonus: 0.05 } },
    dragon_companero: { id: 'dragon_companero', name: 'Dragón Cría (Compañero)', type: 'companero', rarity: 'legendario', icon: '🐉', desc: 'Otorga +20 de ataque y +5% de Oro pasivo.', stats: { attack: 20, goldBonus: 0.05 } },
    golem_companero: { id: 'golem_companero', name: 'Golemito (Compañero)', type: 'companero', rarity: 'raro', icon: '🗿', desc: 'Otorga +15 de defensa pasiva en combates.', stats: { defense: 15 } },

    // Objetos Únicos
    corona_primer_hunter: { id: 'corona_primer_hunter', name: 'Corona del Primer Hunter', type: 'objeto_especial', rarity: 'unico', icon: '👑', desc: 'Objeto único e irrepetible. Demuestra la constancia absoluta durante 365 días en el Sistema. Otorga +50 AP pasivo.', stats: { attack: 50 } }
};

// Lógica de Combate por Turnos
class BattleEngine {
    constructor(playerStats, playerAP, equippedWeapon, playerClass, enemyId, onLog, onUpdate) {
        this.playerMaxHp = 100 + playerStats.spirit.current * 5 + (playerStats.defense.current * 2);
        this.playerHp = this.playerMaxHp;
        this.playerAP = playerAP;
        this.playerDefense = playerStats.defense.current;
        this.playerClass = playerClass;
        this.equippedWeapon = equippedWeapon;

        // Cargar enemigo
        const baseEnemy = BESTIARY[enemyId];
        this.enemyName = baseEnemy.name;
        this.enemyIcon = baseEnemy.icon;
        
        // Escalamiento del enemigo según nivel de jugador
        const playerLvl = playerStats.level || 1;
        const enemyScale = 1 + (playerLvl - 1) * 0.04; // +4% de poder por nivel de jugador
        this.enemyMaxHp = Math.round(baseEnemy.hp * enemyScale);
        this.enemyHp = this.enemyMaxHp;
        this.enemyAttack = Math.round(baseEnemy.attack * enemyScale);
        this.enemyDefense = Math.round(baseEnemy.defense * enemyScale);
        this.enemyBaseXp = baseEnemy.xp;
        this.enemyBaseGold = baseEnemy.gold;
        this.enemyStatusEffect = baseEnemy.statusEffect || null;
        this.enemyLootTable = baseEnemy.loot || [];
        this.enemyLevel = Math.max(1, Math.round(playerLvl + (Math.random() * 4 - 2))); // Rango nivel +-2
        
        this.playerStatus = { burn: 0, freeze: 0, paralysis: 0, poison: 0, bleed: 0, weakness: 0, stun: 0 };
        this.enemyStatus = { burn: 0, freeze: 0, paralysis: 0, poison: 0, bleed: 0, weakness: 0, stun: 0 };
        
        this.turn = 1;
        this.isOver = false;
        this.onLog = onLog;
        this.onUpdate = onUpdate;
    }

    start() {
        this.onLog(`⚔️ ¡Comienza el combate contra ${this.enemyName} (Nivel ${this.enemyLevel})!`);
        this.onLog(`💡 Tienes el primer turno. HP: ${Math.round(this.playerHp)}/${Math.round(this.playerMaxHp)}`);
        this.onUpdate(this);
    }

    // Turno del Jugador - ATACAR
    playerAttack() {
        if (this.isOver) return;

        // Comprobación de estados que impiden actuar
        if (this.checkPlayerCantAct()) return;

        // Cálculo de daño
        let isCrit = Math.random() < 0.15; // 15% crítico base
        let damage = this.playerAP - this.enemyDefense;
        damage = Math.max(5, Math.round(damage * (1 + (Math.random() * 0.2 - 0.1)))); // Rango +-10%
        
        if (isCrit) {
            damage = Math.round(damage * 1.5);
            this.onLog(`💥 ¡Golpe Crítico! Infliges ${damage} de daño a ${this.enemyName}.`);
        } else {
            this.onLog(`🗡️ Atacas a ${this.enemyName} e infliges ${damage} de daño.`);
        }

        // Posibilidad de aplicar estados del arma
        if (this.equippedWeapon && this.equippedWeapon.stats.effect) {
            const effect = this.equippedWeapon.stats.effect;
            if (Math.random() < 0.35) { // 35% aplicar estado
                this.enemyStatus[effect] = 3; // 3 turnos
                this.onLog(`🔥 El efecto del arma aplica ${effect.toUpperCase()} a ${this.enemyName}.`);
            }
        }

        this.enemyHp = Math.max(0, this.enemyHp - damage);
        this.onUpdate(this);
        
        if (this.enemyHp <= 0) {
            this.victory();
        } else {
            this.endPlayerTurn();
        }
    }

    // Turno del Jugador - DEFENDER
    playerDefend() {
        if (this.isOver) return;
        if (this.checkPlayerCantAct()) return;

        this.onLog(`🛡️ Te pones en guardia. El daño enemigo se reducirá en el siguiente turno.`);
        this.playerStatus.defending = true;

        // Clases específicas tienen extras (Paladín cura)
        if (this.playerClass === 'guerrero') {
            const healVal = Math.round(this.playerMaxHp * 0.05); // Recupera 5% vida
            this.playerHp = Math.min(this.playerMaxHp, this.playerHp + healVal);
            this.onLog(`✨ Habilidad de Guerrero: Recuperas ${healVal} HP al defender.`);
        }

        this.onUpdate(this);
        this.endPlayerTurn();
    }

    // Turno del Jugador - USAR OBJETO
    playerUseItem(itemInstance, consumeCallback) {
        if (this.isOver) return;
        if (this.checkPlayerCantAct()) return;

        const dbItem = ITEMS_DATABASE[itemInstance.itemId];
        if (!dbItem || dbItem.type !== 'consumible') return;

        this.onLog(`🎒 Utilizas ${dbItem.name}.`);
        
        if (dbItem.effect.type === 'heal') {
            const healVal = dbItem.effect.value;
            this.playerHp = Math.min(this.playerMaxHp, this.playerHp + healVal);
            this.onLog(`💚 Recuperas ${healVal} HP.`);
        } else if (dbItem.effect.type === 'cleanse') {
            this.playerStatus.poison = 0;
            this.playerStatus.bleed = 0;
            this.onLog(`✨ Te purificas de veneno y sangrado.`);
        } else if (dbItem.effect.type === 'damage_effect') {
            const dmg = dbItem.effect.value;
            const status = dbItem.effect.status;
            this.enemyHp = Math.max(0, this.enemyHp - dmg);
            this.enemyStatus[status] = 3;
            this.onLog(`💥 Detonación: ${dmg} de daño a ${this.enemyName} y aplica ${status.toUpperCase()}.`);
        }

        // Consumir objeto
        consumeCallback(itemInstance);

        this.onUpdate(this);

        if (this.enemyHp <= 0) {
            this.victory();
        } else {
            this.endPlayerTurn();
        }
    }

    // Verificar si el jugador no puede actuar debido a estados
    checkPlayerCantAct() {
        if (this.playerStatus.stun > 0) {
            this.onLog(`💫 Estás aturdido. Pierdes el turno.`);
            this.playerStatus.stun--;
            this.endPlayerTurn();
            return true;
        }
        if (this.playerStatus.freeze > 0) {
            if (Math.random() < 0.6) {
                this.onLog(`❄️ Estás congelado. No puedes moverte este turno.`);
                this.playerStatus.freeze--;
                this.endPlayerTurn();
                return true;
            } else {
                this.onLog(`❄️ Te liberas parcialmente del hielo y logras actuar.`);
                this.playerStatus.freeze--;
            }
        }
        if (this.playerStatus.paralysis > 0) {
            if (Math.random() < 0.4) {
                this.onLog(`⚡ La parálisis entumece tus músculos. No puedes actuar.`);
                this.playerStatus.paralysis--;
                this.endPlayerTurn();
                return true;
            }
            this.playerStatus.paralysis--;
        }
        return false;
    }

    endPlayerTurn() {
        // Procesar daño por estados del jugador al final de su turno
        this.processStatusDamage('player');
        
        if (this.playerHp <= 0) {
            this.defeat();
            return;
        }

        // Si sobrevive, turno del enemigo
        setTimeout(() => {
            this.enemyTurn();
        }, 1200);
    }

    enemyTurn() {
        if (this.isOver) return;

        // Comprobación de estados del enemigo que impiden actuar
        if (this.enemyStatus.stun > 0) {
            this.onLog(`💫 ${this.enemyName} está aturdido y no puede actuar.`);
            this.enemyStatus.stun--;
            this.endEnemyTurn();
            return;
        }
        if (this.enemyStatus.freeze > 0) {
            if (Math.random() < 0.6) {
                this.onLog(`❄️ ${this.enemyName} está completamente congelado.`);
                this.enemyStatus.freeze--;
                this.endEnemyTurn();
                return;
            }
            this.enemyStatus.freeze--;
        }
        if (this.enemyStatus.paralysis > 0) {
            if (Math.random() < 0.4) {
                this.onLog(`⚡ La parálisis impide que ${this.enemyName} ataque.`);
                this.enemyStatus.paralysis--;
                this.endEnemyTurn();
                return;
            }
            this.enemyStatus.paralysis--;
        }

        // Acción enemiga básica
        let dmg = this.enemyAttack - (this.playerStatus.defending ? this.playerDefense * 2 : this.playerDefense);
        dmg = Math.max(3, Math.round(dmg * (1 + (Math.random() * 0.2 - 0.1))));

        if (this.playerStatus.defending) {
            this.onLog(`🛡️ Defiendes el golpe: ${this.enemyName} te hace solo ${dmg} de daño.`);
            this.playerStatus.defending = false;
        } else {
            this.onLog(`👹 ${this.enemyName} ataca y te causa ${dmg} de daño.`);
        }

        this.playerHp = Math.max(0, this.playerHp - dmg);

        // Probabilidad de aplicar estado alterado del enemigo
        if (this.enemyStatusEffect && Math.random() < 0.3) {
            this.playerStatus[this.enemyStatusEffect] = 3;
            this.onLog(`⚠️ El ataque enemigo te inflige ${this.enemyStatusEffect.toUpperCase()}.`);
        }

        if (this.playerHp <= 0) {
            this.defeat();
        } else {
            this.endEnemyTurn();
        }
    }

    endEnemyTurn() {
        // Procesar daño por estados del enemigo al final de su turno
        this.processStatusDamage('enemy');

        if (this.enemyHp <= 0) {
            this.victory();
            return;
        }

        // Siguiente turno
        this.turn++;
        this.onLog(`💡 Turno ${this.turn}. HP: ${Math.round(this.playerHp)}/${Math.round(this.playerMaxHp)} | Enemigo HP: ${Math.round(this.enemyHp)}/${Math.round(this.enemyMaxHp)}`);
        this.onUpdate(this);
    }

    // Procesar daño continuo de Veneno, Sangrado, Quemadura
    processStatusDamage(target) {
        const status = target === 'player' ? this.playerStatus : this.enemyStatus;
        const name = target === 'player' ? 'Tú' : this.enemyName;
        const isPlayer = target === 'player';

        if (status.poison > 0) {
            // Veneno hace daño creciente
            const dmg = (4 - status.poison) * 8; 
            if (isPlayer) this.playerHp = Math.max(0, this.playerHp - dmg);
            else this.enemyHp = Math.max(0, this.enemyHp - dmg);
            this.onLog(`☠️ ${name} sufre ${dmg} de daño por VENENO.`);
            status.poison--;
        }

        if (status.bleed > 0) {
            const dmg = 15; // Daño fijo
            if (isPlayer) this.playerHp = Math.max(0, this.playerHp - dmg);
            else this.enemyHp = Math.max(0, this.enemyHp - dmg);
            this.onLog(`🩸 ${name} sufre ${dmg} de daño por SANGRADO.`);
            status.bleed--;
        }

        if (status.burn > 0) {
            const dmg = 12;
            if (isPlayer) this.playerHp = Math.max(0, this.playerHp - dmg);
            else this.enemyHp = Math.max(0, this.enemyHp - dmg);
            this.onLog(`🔥 ${name} sufre ${dmg} de daño por QUEMADURA.`);
            status.burn--;
        }
    }

    victory() {
        this.isOver = true;
        this.onLog(`🎉 ¡Victoria! Has derrotado a ${this.enemyName}.`);
        
        // Calcular recompensas
        const xpGained = Math.round(this.enemyBaseXp * (1 + (Math.random() * 0.2 - 0.1)));
        const goldGained = Math.round(this.enemyBaseGold * (1 + (Math.random() * 0.2 - 0.1)));
        
        // Roll de loot
        const droppedItems = [];
        this.enemyLootTable.forEach(entry => {
            if (Math.random() < entry.chance) {
                droppedItems.push(entry.item);
            }
        });

        // En jefes finales dar cofres
        if (this.enemyName.includes('(Jefe)')) {
            const rng = Math.random();
            if (rng < 0.1) droppedItems.push('cofre_legendario');
            else if (rng < 0.3) droppedItems.push('cofre_epico');
            else if (rng < 0.6) droppedItems.push('cofre_raro');
            else droppedItems.push('cofre_comun');
        }

        this.rewards = {
            xp: xpGained,
            gold: goldGained,
            loot: droppedItems
        };
        
        this.onUpdate(this);
    }

    defeat() {
        this.isOver = true;
        this.onLog(`💀 Has caído en combate ante ${this.enemyName}.`);
        this.onLog(`ℹ️ No pierdes objetos ni estadísticas base. El Portal se cierra.`);
        this.rewards = null;
        this.onUpdate(this);
    }
}

// Obtener la receta para forjar un objeto
function getRecipeDetails(recipeId) {
    const dbRecipe = ITEMS_DATABASE[recipeId];
    if (dbRecipe && dbRecipe.type === 'receta') {
        return dbRecipe.recipe;
    }
    return null;
}

window.PORTALS_CONFIG = PORTALS_CONFIG;
window.BESTIARY = BESTIARY;
window.ITEMS_DATABASE = ITEMS_DATABASE;
window.BattleEngine = BattleEngine;
window.getRecipeDetails = getRecipeDetails;
console.log('RPG system (rpg.js) cargado correctamente.');
