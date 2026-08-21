// app.js - Lógica Principal, Enrutamiento de Pantallas, Sonidos Sintéticos y Renderizado UI de LEVEL UP

// --------------------------------------------------------------------------
// 1. SISTEMA DE AUDIO SINTÉTICO (Web Audio API)
// --------------------------------------------------------------------------
let audioCtx = null;

function getAudioContext() {
    if (!audioCtx) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === 'suspended') {
        audioCtx.resume();
    }
    return audioCtx;
}

function playTone(frequency, type, duration, volume = 0.1) {
    try {
        const ctx = getAudioContext();
        const osc = ctx.createOscillator();
        const gainNode = ctx.createGain();

        osc.type = type || 'sine';
        osc.frequency.setValueAtTime(frequency, ctx.currentTime);
        
        gainNode.gain.setValueAtTime(volume, ctx.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + duration);

        osc.connect(gainNode);
        gainNode.connect(ctx.destination);

        osc.start();
        osc.stop(ctx.currentTime + duration);
    } catch (e) {
        console.warn('Audio desactivado o bloqueado por el navegador:', e);
    }
}

// Melodías predefinidas
const sounds = {
    click() {
        playTone(880, 'sine', 0.08, 0.05);
    },
    activation() {
        playTone(330, 'sawtooth', 0.2, 0.08);
        setTimeout(() => playTone(440, 'sawtooth', 0.2, 0.08), 150);
        setTimeout(() => playTone(660, 'sawtooth', 0.3, 0.08), 300);
    },
    levelUp() {
        const notes = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]; // Do Mi Sol Do Mi Sol
        notes.forEach((freq, idx) => {
            setTimeout(() => {
                playTone(freq, 'triangle', 0.4, 0.12);
            }, idx * 100);
        });
    },
    missionComplete() {
        playTone(523.25, 'sine', 0.15, 0.08); // Do
        setTimeout(() => playTone(659.25, 'sine', 0.15, 0.08), 120); // Mi
        setTimeout(() => playTone(783.99, 'sine', 0.15, 0.08), 240); // Sol
        setTimeout(() => playTone(987.77, 'sine', 0.3, 0.1), 360);   // Si
    },
    combatHit() {
        // Ruido sintético de golpe
        try {
            const ctx = getAudioContext();
            const bufferSize = ctx.sampleRate * 0.1; // 0.1 segundos
            const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
            const data = buffer.getChannelData(0);
            for (let i = 0; i < bufferSize; i++) {
                data[i] = Math.random() * 2 - 1;
            }
            const noise = ctx.createBufferSource();
            noise.buffer = buffer;
            const filter = ctx.createBiquadFilter();
            filter.type = 'lowpass';
            filter.frequency.value = 400; // Sonido sordo de impacto

            const gain = ctx.createGain();
            gain.gain.setValueAtTime(0.2, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1);

            noise.connect(filter);
            filter.connect(gain);
            gain.connect(ctx.destination);
            noise.start();
        } catch (e) {
            playTone(150, 'sawtooth', 0.1, 0.15); // Fallback
        }
    },
    heal() {
        playTone(880, 'sine', 0.2, 0.06);
        setTimeout(() => playTone(1100, 'sine', 0.2, 0.06), 100);
        setTimeout(() => playTone(1320, 'sine', 0.3, 0.06), 200);
    }
};

// --------------------------------------------------------------------------
// 2. ESTADO GLOBAL DE LA APLICACIÓN
// --------------------------------------------------------------------------
let userState = {
    registered: false,
    name: 'Franco',
    level: 1,
    xp: 0,
    rank: 'E',
    userClass: 'guerrero', // 'guerrero', 'estratega', 'desafiante', 'explorador'
    title: 'Principiante',
    createdDate: new Date().toISOString().split('T')[0],
    daysActive: 1,
    totalTimeTrained: 0,
    totalTimeStudied: 0,
    currentStreak: 0,
    maxStreak: 0,
    energy: 5,
    gold: 200,
    lastLoginDate: new Date().toISOString().split('T')[0],
    stats: {
        strength: { base: 10, current: 10 },
        intelligence: { base: 10, current: 10 },
        discipline: { base: 10, current: 10 },
        spirit: { base: 10, current: 10 },
        defense: { base: 10, current: 10 }
    },
    settings: {
        scalingEnabled: true,
        pauseAllowed: false
    }
};

let activeFocusSession = null;
let activeBattle = null;
let currentPortalInfo = null;
let currentPortalStage = 0; // índice combate actual del portal

// --------------------------------------------------------------------------
// 3. INICIALIZACIÓN
// --------------------------------------------------------------------------
window.addEventListener('DOMContentLoaded', async () => {
    generateFloatingParticles();
    
    // Inicializar base de datos e intentar cargar datos con un timeout de seguridad
    try {
        const dbInitPromise = (async () => {
            await window.initDB();
            const loadedUser = await window.dbSettings.get('user_profile');
            if (loadedUser) {
                userState = loadedUser;
            }
        })();
        const timeoutPromise = new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Timeout al abrir la base de datos local')), 8000)
        );
        await Promise.race([dbInitPromise, timeoutPromise]);
    } catch (e) {
        console.error('Error cargando IndexedDB (usando estado en memoria):', e);
    }

    // Registrar Service Worker para PWA
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('./sw.js')
            .then(reg => console.log('Service Worker registrado con éxito:', reg.scope))
            .catch(err => console.warn('Service Worker falló al registrarse:', err));
    }

    // Configurar listeners generales del DOM
    setupEventListeners();
    
    // Iniciar flujo de pantallas
    startAppFlow();
});

// Generar partículas sutiles flotantes en el fondo
function generateFloatingParticles() {
    const container = document.getElementById('particles-container');
    if (!container) return;
    container.innerHTML = '';
    const colors = ['particle', 'particle particle-purple'];
    
    for (let i = 0; i < 15; i++) {
        const particle = document.createElement('div');
        particle.className = colors[Math.floor(Math.random() * colors.length)];
        
        const size = Math.random() * 4 + 2;
        particle.style.width = `${size}px`;
        particle.style.height = `${size}px`;
        
        particle.style.left = `${Math.random() * 100}vw`;
        particle.style.animationDuration = `${Math.random() * 15 + 10}s`;
        particle.style.animationDelay = `${Math.random() * 8}s`;
        
        container.appendChild(particle);
    }
}

// --------------------------------------------------------------------------
// 4. FLUJO DE PANTALLAS Y ENRUTAMIENTO
// --------------------------------------------------------------------------
function startAppFlow() {
    if (!userState.registered) {
        // Mostrar Splash Screen por 2 segundos y luego ir a calibración
        showScreen('screen-splash');
        setTimeout(() => {
            sounds.activation();
            showScreen('screen-calibration');
            initCalibrationForm();
        }, 2000);
    } else {
        // Mostrar Splash Screen por 2 segundos y luego ir a Home
        showScreen('screen-splash');
        setTimeout(() => {
            sounds.activation();
            checkAndApplyDailyReset();
            showScreen('screen-home');
            renderTabHome();
        }, 2000);
    }
}

function showScreen(screenId) {
    document.querySelectorAll('.screen').forEach(scr => scr.classList.remove('active'));
    
    const target = document.getElementById(screenId);
    if (target) {
        target.classList.add('active');
    }
    
    // Ocultar barra superior e inferior en Splash y Calibración y Enfoque
    const header = document.querySelector('header');
    const nav = document.querySelector('nav');
    if (screenId === 'screen-splash' || screenId === 'screen-calibration' || screenId === 'screen-timer') {
        if (header) header.style.display = 'none';
        if (nav) nav.style.display = 'none';
    } else {
        if (header) header.style.display = 'flex';
        if (nav) nav.style.display = 'flex';
    }
}

function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.addEventListener('click', (e) => {
            sounds.click();
            document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
            btn.classList.add('active');
            
            const tabName = btn.dataset.tab;
            if (tabName === 'home') {
                showScreen('screen-home');
                renderTabHome();
            } else if (tabName === 'missions') {
                showScreen('screen-missions');
                renderTabMissions();
            } else if (tabName === 'rpg') {
                showScreen('screen-rpg');
                renderTabRPG();
            } else if (tabName === 'inventory') {
                showScreen('screen-inventory');
                renderTabInventory();
            } else if (tabName === 'profile') {
                showScreen('screen-profile');
                renderTabProfile();
            }
        });
    });

    // Configuración modal
    document.getElementById('btn-header-settings').addEventListener('click', () => {
        sounds.click();
        openSettingsModal();
    });

    document.getElementById('btn-close-settings').addEventListener('click', () => {
        sounds.click();
        closeModal('settings-modal');
    });

    // Crear Misión botón flotante
    document.getElementById('btn-create-mission').addEventListener('click', () => {
        sounds.click();
        openCreateMissionModal();
    });
}

// --------------------------------------------------------------------------
// 5. CALIBRACIÓN INICIAL (Primer inicio)
// --------------------------------------------------------------------------
let calibrationSlideIndex = 0;
let tempCalibrationData = { name: '', avatar: 'knight', goal: 'fisico', physicalDays: '0', studyTime: 'nada', consistency: 'principiante' };

function initCalibrationForm() {
    calibrationSlideIndex = 0;
    showCalibrationSlide();
    
    // Select cards listeners
    document.querySelectorAll('.select-card').forEach(card => {
        card.addEventListener('click', () => {
            sounds.click();
            const group = card.dataset.group;
            const value = card.dataset.value;
            
            // Desmarcar otros del mismo grupo
            document.querySelectorAll(`.select-card[data-group="${group}"]`).forEach(c => c.classList.remove('selected'));
            card.classList.add('selected');
            
            tempCalibrationData[group] = value;
        });
    });

    // Siguiente slide botones
    document.querySelectorAll('.btn-next-slide').forEach(btn => {
        btn.addEventListener('click', () => {
            sounds.click();
            if (calibrationSlideIndex === 0) {
                const nameInp = document.getElementById('calib-name').value.trim();
                if (!nameInp) {
                    alert('Por favor, ingresa tu nombre para inicializar el sistema.');
                    return;
                }
                tempCalibrationData.name = nameInp;
            }
            
            calibrationSlideIndex++;
            showCalibrationSlide();
        });
    });

    // Guardar calibración y registrar
    document.getElementById('btn-complete-calibration').addEventListener('click', async () => {
        sounds.levelUp();
        
        userState.registered = true;
        userState.name = tempCalibrationData.name;
        userState.selectedAvatar = tempCalibrationData.avatar;
        
        // Asignar clase recomendada basada en objetivo
        if (tempCalibrationData.goal === 'fisico') userState.userClass = 'guerrero';
        else if (tempCalibrationData.goal === 'aprender') userState.userClass = 'estratega';
        else if (tempCalibrationData.goal === 'disciplinado') userState.userClass = 'desafiante';
        else userState.userClass = 'explorador';

        // Calibrar estadísticas iniciales basándose en el cuestionario
        calibrateInitialStats();
        
        // Guardar en la base de datos
        await saveUserProfile();
        
        // Crear las primeras misiones diarias
        const initialMissions = window.generateDailyMissions(tempCalibrationData.goal, 1);
        for (const mission of initialMissions) {
            await window.dbMissions.save(mission);
        }

        // Desbloquear primer logro
        await unlockAchievement('primer_paso');
        
        // Inicializar títulos
        await unlockTitle('principiante');

        showScreen('screen-home');
        document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
        document.querySelector('.nav-item[data-tab="home"]').classList.add('active');
        renderTabHome();
    });
}

function showCalibrationSlide() {
    document.querySelectorAll('.calibration-slide').forEach((slide, idx) => {
        if (idx === calibrationSlideIndex) {
            slide.classList.add('active');
        } else {
            slide.classList.remove('active');
        }
    });
}

function calibrateInitialStats() {
    // Si entrena mucho, más fuerza. Si estudia mucho, más inteligencia
    let strength = 10;
    let intelligence = 10;
    let discipline = 10;
    let spirit = 10;
    let defense = 10;

    // Actividad física
    if (tempCalibrationData.physicalDays === '3-5') strength += 3;
    else if (tempCalibrationData.physicalDays === 'todos') strength += 5;

    // Estudio
    if (tempCalibrationData.studyTime === '30m') intelligence += 2;
    else if (tempCalibrationData.studyTime === '1h') intelligence += 4;
    else if (tempCalibrationData.studyTime === '2h+') intelligence += 6;

    // Hábitos
    if (tempCalibrationData.consistency === 'intermedio') discipline += 3;
    else if (tempCalibrationData.consistency === 'avanzado') discipline += 5;

    userState.stats.strength = { base: strength, current: strength };
    userState.stats.intelligence = { base: intelligence, current: intelligence };
    userState.stats.discipline = { base: discipline, current: discipline };
    userState.stats.spirit = { base: spirit, current: spirit };
    userState.stats.defense = { base: defense, current: defense };
    
    // Equipamiento por defecto
    userState.equippedItems = ['espada_entrenamiento', 'armadura_entrenamiento'];
    userState.companions = [];
    userState.unlockedTitles = ['principiante'];
    userState.activeTitle = 'principiante';
    userState.gold = 300;
}

// --------------------------------------------------------------------------
// 6. RENDERIZACIÓN PESTAÑA: HOME (Inicio)
// --------------------------------------------------------------------------
async function renderTabHome() {
    // Encabezado
    document.getElementById('header-user-name').innerText = userState.name;
    document.getElementById('lbl-home-title').innerText = userState.activeTitle ? 
        (window.UNLOCKABLE_TITLES.find(t => t.id === userState.activeTitle)?.name || 'Hunter') : 'Hunter';
    document.getElementById('badge-home-level').innerText = `LV ${userState.level}`;
    
    // Racha y Oro
    document.getElementById('val-home-streak').innerText = `${userState.currentStreak} Días`;
    document.getElementById('val-home-gold').innerText = `${userState.gold} Oro`;

    // Barra XP
    const nextLvlXp = window.getXPForLevel(userState.level);
    const xpPercent = Math.min(100, (userState.xp / nextLvlXp) * 100);
    document.getElementById('home-xp-bar').style.width = `${xpPercent}%`;
    document.getElementById('lbl-home-xp').innerText = `${userState.xp} / ${nextLvlXp} XP`;

    // Cargar misiones diarias resumidas
    const mList = await window.dbMissions.getAll();
    const todayStr = new Date().toISOString().split('T')[0];
    const dailyMissions = mList.filter(m => m.type === 'diaria' && m.date_created === todayStr);

    const mContainer = document.getElementById('home-missions-list');
    mContainer.innerHTML = '';

    if (dailyMissions.length === 0) {
        mContainer.innerHTML = `<div style="text-align:center; padding:10px; color:rgba(255,255,255,0.4);">No hay misiones recomendadas para hoy. Crea una misión en la pestaña Misiones.</div>`;
    } else {
        dailyMissions.forEach(m => {
            const item = document.createElement('div');
            item.className = `home-mission-item ${m.completed ? 'completed' : ''}`;
            item.addEventListener('click', () => {
                sounds.click();
                openMissionDetails(m);
            });

            item.innerHTML = `
                <div class="home-mission-content">
                    <div class="home-mission-checkbox">${m.completed ? '✓' : ''}</div>
                    <div>
                        <div class="home-mission-title">${m.name}</div>
                        <div class="home-mission-rewards">+${m.reward_xp} XP | +${m.reward_gold} Oro</div>
                    </div>
                </div>
                <div class="difficulty-badge diff-${m.difficulty}">${m.difficulty.replace('_', ' ')}</div>
            `;
            mContainer.appendChild(item);
        });
    }

    // Renderizar resumen barras de estadísticas en home
    const statsArr = ['strength', 'intelligence', 'discipline', 'spirit', 'defense'];
    statsArr.forEach(stat => {
        const val = userState.stats[stat].current;
        const maxVal = 100; // Normalización base
        const percent = Math.min(100, (val / maxVal) * 100);
        document.getElementById(`home-stat-bar-${stat}`).style.width = `${percent}%`;
        document.getElementById(`home-stat-val-${stat}`).innerText = val;
    });

    // Widget Portal Semanal (Solo abre fines de semana: Sábado=6, Domingo=0)
    const today = new Date();
    const dayOfWeek = today.getDay();
    const isWeekend = dayOfWeek === 6 || dayOfWeek === 0;
    const portalWidget = document.getElementById('portal-weekly-widget');

    if (isWeekend) {
        portalWidget.innerHTML = `
            <div class="portal-widget-info">
                <h4>🚪 Portal Semanal Disponible</h4>
                <p>Usa tu energía semanal para entrar al Portal de Combate.</p>
            </div>
            <button class="btn-enter-portal" id="btn-enter-portal-widget">Entrar</button>
        `;
        document.getElementById('btn-enter-portal-widget').addEventListener('click', () => {
            sounds.click();
            document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
            document.querySelector('.nav-item[data-tab="rpg"]').classList.add('active');
            showScreen('screen-rpg');
            renderTabRPG();
        });
    } else {
        // Calcular tiempo restante para el sábado
        let daysToSaturday = (6 - dayOfWeek + 7) % 7;
        if (daysToSaturday === 0) daysToSaturday = 7;
        
        portalWidget.innerHTML = `
            <div class="portal-widget-info">
                <h4 style="color: rgba(255,255,255,0.4);">🚪 Próximo Portal en ${daysToSaturday} Días</h4>
                <p style="color: rgba(255,255,255,0.3);">Disponible todos los sábados y domingos.</p>
            </div>
            <button class="btn-enter-portal" style="background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); color:rgba(255,255,255,0.4);" disabled>Bloqueado</button>
        `;
    }
}

// --------------------------------------------------------------------------
// 7. RENDERIZACIÓN PESTAÑA: MISIONES (Gestión y Timer)
// --------------------------------------------------------------------------
let activeMissionsTab = 'hoy';

function renderTabMissions() {
    // Configurar tabs de misiones
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            sounds.click();
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            activeMissionsTab = btn.dataset.tab;
            loadMissionsList();
        });
    });

    loadMissionsList();
}

async function loadMissionsList() {
    const listContainer = document.getElementById('missions-list-container');
    listContainer.innerHTML = '';

    const allMissions = await window.dbMissions.getAll();
    const todayStr = new Date().toISOString().split('T')[0];
    
    let filtered = [];
    if (activeMissionsTab === 'hoy') {
        filtered = allMissions.filter(m => m.type === 'diaria' && m.date_created === todayStr);
    } else if (activeMissionsTab === 'semana') {
        filtered = allMissions.filter(m => m.type === 'semanal');
    } else if (activeMissionsTab === 'especiales') {
        filtered = allMissions.filter(m => m.type === 'especial');
    } else if (activeMissionsTab === 'personalizadas') {
        filtered = allMissions.filter(m => m.type === 'personalizada');
    }

    if (filtered.length === 0) {
        listContainer.innerHTML = `<div style="text-align:center; padding:30px; color:rgba(255,255,255,0.4);">No hay misiones registradas en esta sección. ¡Crea una nueva misión con el botón +!</div>`;
        return;
    }

    filtered.forEach(m => {
        const card = document.createElement('div');
        card.className = `mission-card border-${m.attribute} ${m.completed ? 'completed' : ''}`;
        card.addEventListener('click', () => {
            sounds.click();
            openMissionDetails(m);
        });

        card.innerHTML = `
            <div class="mission-card-content">
                <div class="mission-card-title">${m.name} ${m.completed ? '✓' : ''}</div>
                <div class="mission-card-desc">${m.desc}</div>
                <div class="mission-card-meta">
                    <span class="meta-item meta-item-xp">🔋 +${m.reward_xp} XP</span>
                    <span class="meta-item meta-item-gold">🟡 +${m.reward_gold} Oro</span>
                    <span class="meta-item meta-item-time">⏱️ ${m.duration} Min</span>
                </div>
            </div>
            <div class="difficulty-badge diff-${m.difficulty}">${m.difficulty.replace('_', ' ')}</div>
        `;
        listContainer.appendChild(card);
    });
}

// Detalles de Misión Modal
function openMissionDetails(mission) {
    const overlay = document.getElementById('mission-detail-modal');
    overlay.classList.add('active');

    document.getElementById('lbl-detail-title').innerText = mission.name;
    document.getElementById('lbl-detail-desc').innerText = mission.desc;
    document.getElementById('lbl-detail-attribute').innerText = `Atributo aumentado: ${mission.attribute.toUpperCase()}`;
    document.getElementById('lbl-detail-duration').innerText = `Tiempo de concentración: ${mission.duration} Minutos`;
    document.getElementById('lbl-detail-xp').innerText = `+${mission.reward_xp} XP`;
    document.getElementById('lbl-detail-gold').innerText = `+${mission.reward_gold} Oro`;
    
    const badge = document.getElementById('lbl-detail-difficulty');
    badge.className = `difficulty-badge diff-${mission.difficulty}`;
    badge.innerText = mission.difficulty.replace('_', ' ');

    const btnStart = document.getElementById('btn-start-mission');
    
    if (mission.completed) {
        btnStart.style.display = 'none';
    } else {
        btnStart.style.display = 'block';
        // Limpiar event listeners previos
        const clone = btnStart.cloneNode(true);
        btnStart.parentNode.replaceChild(clone, btnStart);
        clone.addEventListener('click', () => {
            sounds.activation();
            closeModal('mission-detail-modal');
            launchFocusTimer(mission);
        });
    }

    document.getElementById('btn-close-detail').onclick = () => {
        sounds.click();
        closeModal('mission-detail-modal');
    };

    // Botón Eliminar Misión
    document.getElementById('btn-delete-mission').onclick = async () => {
        sounds.click();
        if (confirm(`¿Seguro que deseas eliminar la misión "${mission.name}"?`)) {
            if (mission.id) {
                await window.dbMissions.delete(mission.id);
            }
            closeModal('mission-detail-modal');
            renderTabMissions();
            if (activeMissionsTab === 'hoy') renderTabHome();
        }
    };

    // Botón Editar Misión
    document.getElementById('btn-edit-mission').onclick = () => {
        sounds.click();
        closeModal('mission-detail-modal');
        openEditMissionModal(mission);
    };
}

function openEditMissionModal(mission) {
    const overlay = document.getElementById('edit-mission-modal');
    overlay.classList.add('active');

    document.getElementById('edit-mission-name').value = mission.name;
    document.getElementById('edit-mission-desc').value = mission.desc;
    document.getElementById('edit-mission-duration').value = mission.duration;
    document.getElementById('edit-mission-difficulty').value = mission.difficulty;

    document.getElementById('btn-save-edit-mission').onclick = async () => {
        sounds.click();
        mission.name = document.getElementById('edit-mission-name').value.trim() || mission.name;
        mission.desc = document.getElementById('edit-mission-desc').value.trim() || mission.desc;
        mission.duration = parseInt(document.getElementById('edit-mission-duration').value) || mission.duration;
        mission.difficulty = document.getElementById('edit-mission-difficulty').value;

        // Recalcular XP / Oro según dificultad
        let baseXP = 30;
        let baseGold = 20;
        if (mission.difficulty === 'muy_facil') { baseXP = 15; baseGold = 10; }
        else if (mission.difficulty === 'facil') { baseXP = 30; baseGold = 20; }
        else if (mission.difficulty === 'normal') { baseXP = 60; baseGold = 45; }
        else if (mission.difficulty === 'dificil') { baseXP = 100; baseGold = 80; }
        else if (mission.difficulty === 'extrema') { baseXP = 160; baseGold = 130; }

        mission.reward_xp = baseXP;
        mission.reward_gold = baseGold;

        await window.dbMissions.save(mission);
        closeModal('edit-mission-modal');
        renderTabMissions();
    };

    document.getElementById('btn-close-edit-mission').onclick = () => {
        sounds.click();
        closeModal('edit-mission-modal');
    };
}

// Lanzar el temporizador de concentración a pantalla completa
let currentFocusTimer = null;
function launchFocusTimer(mission) {
    showScreen('screen-timer');
    
    document.getElementById('timer-m-title').innerText = mission.name;
    document.getElementById('timer-m-attr').innerText = `Registrando Atributo: ${mission.attribute.toUpperCase()}`;
    
    const ring = document.getElementById('timer-ring');
    const display = document.getElementById('timer-display');
    const totalLength = 628; // Circunferencia de r=100

    currentFocusTimer = window.startFocusTimer(mission, 
        // En cada Tick (1 segundo)
        (timeLeft, totalSeconds) => {
            const minutes = Math.floor(timeLeft / 60);
            const seconds = timeLeft % 60;
            display.innerText = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
            
            // Actualizar círculo SVG
            const percentLeft = timeLeft / totalSeconds;
            const offset = totalLength - (percentLeft * totalLength);
            ring.style.strokeDashoffset = offset;
        },
        // Al completar con éxito
        async (completedMission) => {
            sounds.missionComplete();
            currentFocusTimer.stop();
            currentFocusTimer = null;
            showScreen('screen-missions');
            
            // Marcar misión completada en BD
            completedMission.completed = true;
            completedMission.time_spent = completedMission.duration;
            await window.dbMissions.save(completedMission);

            // Recompensas
            userState.xp += completedMission.reward_xp;
            userState.gold += completedMission.reward_gold;

            // Registrar ganancia de atributo en el historial y sumarla
            const attr = completedMission.attribute;
            let amount = 1; // Base +1
            if (completedMission.difficulty === 'dificil') amount = 2;
            if (completedMission.difficulty === 'extrema') amount = 3;

            userState.stats[attr].current += amount;
            userState.stats[attr].base += amount;

            await window.dbHistory.add({
                date: new Date().toISOString().split('T')[0],
                text: `+${amount} ${attr.charAt(0).toUpperCase() + attr.slice(1)}`,
                attribute: attr,
                value: amount,
                timestamp: Date.now()
            });

            // Registrar en el calendario
            await saveCalendarEntry(completedMission.reward_xp, completedMission.duration, attr, amount);

            // Verificar si sube de nivel
            let levelUpOccurred = false;
            while (userState.xp >= window.getXPForLevel(userState.level)) {
                userState.xp -= window.getXPForLevel(userState.level);
                userState.level++;
                levelUpOccurred = true;
            }

            if (levelUpOccurred) {
                setTimeout(() => {
                    sounds.levelUp();
                    alert(`⚡ ¡ENHORABUENA! Tu poder ha incrementado. Has subido al nivel ${userState.level}. El Sistema te felicita.`);
                }, 800);
            }

            // Actualizar estadísticas de racha
            userState.currentStreak++;
            if (userState.currentStreak > userState.maxStreak) {
                userState.maxStreak = userState.currentStreak;
            }

            // Si es misión especial de recuperación, limpiar decadencia
            if (completedMission.is_recovery) {
                userState.energy = 5;
            }

            await saveUserProfile();
            renderTabMissions();
        },
        // Si cancela
        () => {
            // No hacer nada directamente aquí
        }
    );

    // Botón cancelar temporizador
    document.getElementById('btn-cancel-timer').onclick = () => {
        sounds.click();
        if (confirm('¿Deseas abandonar la misión? Si confirmas, la misión fallará y perderás tu multiplicador de racha activa.')) {
            const failedMission = window.cancelFocusTimer();
            if (currentFocusTimer) {
                currentFocusTimer.stop();
                currentFocusTimer = null;
            }
            
            // Romper racha
            userState.currentStreak = 0;
            saveUserProfile();

            showScreen('screen-missions');
            renderTabMissions();
            alert('Misión Fallida. La persistencia es el único camino para no ser un cazador débil. Vuelve a intentarlo.');
        }
    };
}

async function saveCalendarEntry(xpGained, minutesGained, attrName, attrVal) {
    const todayStr = new Date().toISOString().split('T')[0];
    let entry = await window.dbCalendar.getByDate(todayStr);

    if (!entry) {
        entry = {
            date: todayStr,
            status: 'blue', // Parcial inicialmente
            xp: 0,
            hours: 0,
            stats: { strength: 0, intelligence: 0, discipline: 0, spirit: 0, defense: 0 }
        };
    }

    entry.xp += xpGained;
    entry.hours += (minutesGained / 60);
    entry.stats[attrName] += attrVal;

    // Actualizar estado de completado según misiones del día
    const mList = await window.dbMissions.getAll();
    const dailyMissions = mList.filter(m => m.type === 'diaria' && m.date_created === todayStr);
    const completedCount = dailyMissions.filter(m => m.completed).length;

    if (dailyMissions.length > 0 && completedCount === dailyMissions.length) {
        entry.status = 'green'; // 100% completadas
    } else if (completedCount > 0) {
        entry.status = 'blue'; // Parcial
    } else {
        entry.status = 'red'; // Sin completar
    }

    await window.dbCalendar.save(entry);
}

// Crear Misión Modal
function openCreateMissionModal() {
    const overlay = document.getElementById('create-mission-modal');
    overlay.classList.add('active');

    // Limpiar formulario
    document.getElementById('mission-name').value = '';
    document.getElementById('mission-desc').value = '';
    document.getElementById('mission-duration').value = '15';
    document.getElementById('mission-attribute').value = 'strength';
    document.getElementById('mission-difficulty').value = 'normal';

    const btnSave = document.getElementById('btn-save-mission');
    const clone = btnSave.cloneNode(true);
    btnSave.parentNode.replaceChild(clone, btnSave);
    
    clone.addEventListener('click', async () => {
        sounds.click();
        const name = document.getElementById('mission-name').value.trim();
        const desc = document.getElementById('mission-desc').value.trim();
        const duration = parseInt(document.getElementById('mission-duration').value);
        const attribute = document.getElementById('mission-attribute').value;
        const difficulty = document.getElementById('mission-difficulty').value;

        if (!name || !desc) {
            alert('Por favor, completa todos los campos obligatorios.');
            return;
        }

        // Calcular recompensas base según dificultad
        let baseXP = 30;
        let baseGold = 20;

        if (difficulty === 'muy_facil') { baseXP = 15; baseGold = 10; }
        else if (difficulty === 'facil') { baseXP = 30; baseGold = 20; }
        else if (difficulty === 'normal') { baseXP = 60; baseGold = 45; }
        else if (difficulty === 'dificil') { baseXP = 100; baseGold = 80; }
        else if (difficulty === 'extrema') { baseXP = 160; baseGold = 130; }

        const newMission = window.createMissionInstance({
            name, desc, duration, difficulty, reward_xp: baseXP, reward_gold: baseGold
        }, attribute, 'personalizada', userState.level);

        await window.dbMissions.save(newMission);
        closeModal('create-mission-modal');
        renderTabMissions();
    });

    document.getElementById('btn-close-create').onclick = () => {
        sounds.click();
        closeModal('create-mission-modal');
    };
}

// --------------------------------------------------------------------------
// 8. RENDERIZACIÓN PESTAÑA: PERFIL (Detalle y Radar Chart)
// --------------------------------------------------------------------------
async function renderTabProfile() {
    document.getElementById('lbl-profile-name').innerText = userState.name;
    
    // Obtener información de clase
    const clsInfo = window.CHARACTER_CLASSES[userState.userClass];
    document.getElementById('lbl-profile-class').innerText = `${clsInfo ? clsInfo.name : 'Sin Clase'} ${clsInfo ? clsInfo.icon : ''}`;
    
    // Título activo
    const activeTitleObj = window.UNLOCKABLE_TITLES.find(t => t.id === userState.activeTitle);
    document.getElementById('lbl-profile-title').innerText = activeTitleObj ? activeTitleObj.name : 'Hunter Novato';
    
    document.getElementById('lbl-profile-level').innerText = `NIVEL: ${userState.level}`;
    document.getElementById('lbl-profile-xp-raw').innerText = `EXPERIENCIA: ${userState.xp} / ${window.getXPForLevel(userState.level)} XP`;

    // Rango
    const allMissions = await window.dbMissions.getAll();
    const completedMissionsCount = allMissions.filter(m => m.completed).length;
    const rankInfo = window.calculateRank(userState.level, completedMissionsCount, userState.daysActive);
    
    const rankTag = document.getElementById('profile-rank-tag-val');
    rankTag.innerText = rankInfo.rank;
    
    // Cambiar fondo del avatar según el Rango
    const container = document.getElementById('profile-avatar-container');
    container.style.backgroundImage = `radial-gradient(circle at bottom, rgba(6,11,25,0.7) 0%, rgba(2,4,10,0.95) 100%)`;
    
    // Cambiar la imagen del avatar (simulado o generado)
    const avatarImg = document.getElementById('profile-avatar-img');
    avatarImg.src = `./assets/logo.jpg`; // Por defecto usa el logo generado para dar un toque premium

    // Estadísticas
    const statsList = ['strength', 'intelligence', 'discipline', 'spirit', 'defense'];
    
    // Cargar equipamiento para calcular AP
    const equipped = await getEquippedItems();
    const activeCompanions = []; // Vacío en este MVP
    const titleBonus = activeTitleObj ? activeTitleObj.bonus : 0;
    const apResult = window.calculateAttackPower(userState.stats, userState.userClass, equipped, activeCompanions, titleBonus);
    
    // Actualizar AP en UI
    document.getElementById('profile-val-ap').innerText = apResult.ap;

    statsList.forEach(stat => {
        const base = userState.stats[stat].base;
        const current = userState.stats[stat].current;
        document.getElementById(`profile-val-${stat}`).innerText = current;
    });

    // Cambiar clase botón
    document.getElementById('btn-change-class').onclick = () => {
        sounds.click();
        openClassSelectionModal();
    };
}

async function getEquippedItems() {
    const inventory = await window.dbInventory.getAll();
    return inventory.filter(item => item.equipped);
}

function openClassSelectionModal() {
    const overlay = document.getElementById('class-select-modal');
    overlay.classList.add('active');

    const container = document.getElementById('class-list-container');
    container.innerHTML = '';

    Object.keys(window.CHARACTER_CLASSES).forEach(key => {
        const cls = window.CHARACTER_CLASSES[key];
        const card = document.createElement('div');
        card.className = `select-card ${userState.userClass === key ? 'selected' : ''}`;
        card.addEventListener('click', async () => {
            sounds.levelUp();
            userState.userClass = key;
            await saveUserProfile();
            closeModal('class-select-modal');
            renderTabProfile();
            alert(`⚔️ Has cambiado tu clase a ${cls.name}. Tu bonificación de clase ha sido recalculada.`);
        });

        card.innerHTML = `
            <div class="select-card-icon">${cls.icon}</div>
            <div class="select-card-info">
                <div class="select-card-title">${cls.name}</div>
                <div class="select-card-desc">${cls.description}</div>
                <div style="font-size:12px; color:var(--color-xp); margin-top:4px;">
                    Bonus: ${cls.bonuses.strength ? `+${cls.bonuses.strength*100}% STR` : ''} 
                    ${cls.bonuses.intelligence ? `+${cls.bonuses.intelligence*100}% INT` : ''}
                    ${cls.bonuses.spirit ? `+${cls.bonuses.spirit*100}% SPI` : ''}
                    ${cls.bonuses.defense ? `+${cls.bonuses.defense*100}% DEF` : ''}
                </div>
            </div>
        `;
        container.appendChild(card);
    });

    document.getElementById('btn-close-class-select').onclick = () => {
        sounds.click();
        closeModal('class-select-modal');
    };
}

// --------------------------------------------------------------------------
// 9. RENDERIZACIÓN PESTAÑA: ESTADÍSTICAS (Historial e Histograma)
// --------------------------------------------------------------------------
async function renderTabProfileStats() {
    showScreen('screen-stats');
    
    // Dibujar Radar Chart animado
    drawRadarChart();
    
    // Rellenar lista de desglose
    const statsList = ['strength', 'intelligence', 'discipline', 'spirit', 'defense'];
    const equipped = await getEquippedItems();
    const titleObj = window.UNLOCKABLE_TITLES.find(t => t.id === userState.activeTitle);
    const titleBonus = titleObj ? titleObj.bonus : 0;
    const apResult = window.calculateAttackPower(userState.stats, userState.userClass, equipped, [], titleBonus);

    // AP principal
    document.getElementById('stats-val-ap').innerText = apResult.ap;

    statsList.forEach(stat => {
        const val = userState.stats[stat].current;
        const base = userState.stats[stat].base;
        const diff = val - base;
        
        document.getElementById(`stats-val-total-${stat}`).innerText = val;
        document.getElementById(`stats-val-breakdown-${stat}`).innerText = `Base: ${base} ${diff > 0 ? `(+${diff} bono)` : ''}`;
    });

    // Cargar historial
    const historyList = await window.dbHistory.getAll();
    const histContainer = document.getElementById('stats-history-list');
    histContainer.innerHTML = '';

    if (historyList.length === 0) {
        histContainer.innerHTML = `<div style="text-align:center; padding:10px; color:rgba(255,255,255,0.4);">No hay modificaciones de atributos registradas hoy. Completa misiones para ganar poder.</div>`;
    } else {
        historyList.forEach(item => {
            const el = document.createElement('div');
            el.className = 'stat-history-item';
            el.innerHTML = `
                <span class="stat-history-date">${item.date}</span>
                <span class="stat-history-text">${item.text}</span>
            `;
            histContainer.appendChild(el);
        });
    }
}

// Dibujar Gráfico de Radar
function drawRadarChart() {
    const canvas = document.getElementById('radar-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    
    // Ajustar dimensiones internas
    canvas.width = 300;
    canvas.height = 240;

    const width = canvas.width;
    const height = canvas.height;
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 2 - 30;

    const stats = ['strength', 'intelligence', 'discipline', 'spirit', 'defense'];
    const labels = ['Fuerza', 'Intel.', 'Disc.', 'Espíritu', 'Defensa'];
    const totalAxes = stats.length;

    // Normalizar valores (valor máx representable = 60 o el mayor stat)
    let maxStatValue = 40;
    stats.forEach(s => {
        if (userState.stats[s].current > maxStatValue) {
            maxStatValue = userState.stats[s].current;
        }
    });

    ctx.clearRect(0, 0, width, height);

    // 1. Dibujar telaraña de fondo (3 niveles concéntricos)
    const webLevels = 3;
    for (let level = 1; level <= webLevels; level++) {
        const lvlRadius = (radius / webLevels) * level;
        ctx.beginPath();
        for (let i = 0; i < totalAxes; i++) {
            const angle = (i * 2 * Math.PI) / totalAxes - Math.PI / 2;
            const x = centerX + lvlRadius * Math.cos(angle);
            const y = centerY + lvlRadius * Math.sin(angle);
            if (i === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }
        ctx.closePath();
        ctx.strokeStyle = 'rgba(59, 130, 246, 0.15)';
        ctx.lineWidth = 1;
        ctx.stroke();
    }

    // 2. Dibujar ejes radiales
    ctx.strokeStyle = 'rgba(59, 130, 246, 0.2)';
    for (let i = 0; i < totalAxes; i++) {
        const angle = (i * 2 * Math.PI) / totalAxes - Math.PI / 2;
        const x = centerX + radius * Math.cos(angle);
        const y = centerY + radius * Math.sin(angle);
        
        ctx.beginPath();
        ctx.moveTo(centerX, centerY);
        ctx.lineTo(x, y);
        ctx.stroke();

        // Escribir etiquetas de los ejes
        ctx.font = 'bold 12px Rajdhani';
        ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
        ctx.textAlign = 'center';
        
        // Ajuste fino de la etiqueta de texto
        const labelRadius = radius + 15;
        const lx = centerX + labelRadius * Math.cos(angle);
        const ly = centerY + labelRadius * Math.sin(angle) + 4;
        ctx.fillText(labels[i], lx, ly);
    }

    // 3. Dibujar polígono de valores del usuario (azul neón transparente)
    ctx.beginPath();
    for (let i = 0; i < totalAxes; i++) {
        const statName = stats[i];
        const val = userState.stats[statName].current;
        const valRatio = Math.min(1.0, val / maxStatValue);
        const valRadius = radius * valRatio;

        const angle = (i * 2 * Math.PI) / totalAxes - Math.PI / 2;
        const x = centerX + valRadius * Math.cos(angle);
        const y = centerY + valRadius * Math.sin(angle);

        if (i === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
    }
    ctx.closePath();
    ctx.fillStyle = 'rgba(124, 58, 237, 0.35)'; // Relleno violeta semitransparente
    ctx.fill();
    ctx.strokeStyle = 'var(--color-primary)';
    ctx.lineWidth = 2;
    ctx.stroke();

    // Dibujar pequeños nodos en las puntas del polígono
    for (let i = 0; i < totalAxes; i++) {
        const statName = stats[i];
        const val = userState.stats[statName].current;
        const valRatio = Math.min(1.0, val / maxStatValue);
        const valRadius = radius * valRatio;

        const angle = (i * 2 * Math.PI) / totalAxes - Math.PI / 2;
        const x = centerX + valRadius * Math.cos(angle);
        const y = centerY + valRadius * Math.sin(angle);

        ctx.beginPath();
        ctx.arc(x, y, 4, 0, 2 * Math.PI);
        ctx.fillStyle = '#ffffff';
        ctx.fill();
        ctx.strokeStyle = 'var(--color-primary)';
        ctx.stroke();
    }
}

// --------------------------------------------------------------------------
// 10. RENDERIZACIÓN PESTAÑA: RPG (Portales y Mazmorras)
// --------------------------------------------------------------------------
function renderTabRPG() {
    // Asegurar que la energía tenga un valor válido (fix para saves anteriores)
    if (userState.energy === undefined || userState.energy === null || userState.energy < 0) {
        userState.energy = 5;
    }

    // Actualizar display de energía dinámicamente
    const energyDisplay = document.getElementById('rpg-energy-display');
    if (energyDisplay) {
        energyDisplay.innerText = `⚡ Energía: ${userState.energy} / 5`;
    }

    const container = document.getElementById('portals-list-container');
    container.innerHTML = '';

    window.PORTALS_CONFIG.forEach(portal => {
        const isLocked = userState.level < portal.minLevel;
        const card = document.createElement('div');
        card.className = `portal-card ${isLocked ? 'locked' : ''}`;
        
        if (!isLocked) {
            card.addEventListener('click', () => {
                sounds.click();
                openPortalStartConfirm(portal);
            });
        }

        card.innerHTML = `
            <div class="portal-info-block">
                <h3>${portal.name}</h3>
                <p>${portal.desc}</p>
                <div style="font-size:12px; color:var(--color-xp); margin-top:4px;">Combates: ${portal.battlesCount} | Nivel Mínimo: ${portal.minLevel}</div>
            </div>
            <div class="portal-badge-rank">${portal.rank}</div>
        `;
        container.appendChild(card);
    });
}

function openPortalStartConfirm(portal) {
    // Garantizar energía válida
    if (userState.energy === undefined || userState.energy === null) {
        userState.energy = 5;
    }

    if (userState.energy < 1) {
        alert('❌ No tienes suficiente Energía Semanal (0/5). Se recarga todos los sábados.');
        return;
    }

    if (confirm(`¿Deseas gastar 1 punto de Energía Semanal para entrar a la mazmorra "${portal.name}"? (Energía actual: ${userState.energy}/5)`)) {
        sounds.activation();

        currentPortalInfo = portal;
        currentPortalStage = 0;

        // Consumir energía SOLO después de verificar que el combate puede iniciar
        try {
            launchPortalFight();
            // Si llegamos aquí, el combate inició correctamente → descontar energía
            userState.energy--;
            saveUserProfile();
            renderTabRPG(); // Actualizar display de energía
        } catch (e) {
            console.error('Error al iniciar combate, energía NO consumida:', e);
            alert('⚠️ Ocurrió un error al iniciar el combate. No se consumió energía. Intenta de nuevo.');
        }
    }
}

// Lanzar el siguiente combate del Portal
function launchPortalFight() {
    const listEnemies = currentPortalInfo.enemies;
    let enemyId = '';
    
    // Si estamos en la última fase del portal, combatir contra el jefe final
    if (currentPortalStage === currentPortalInfo.battlesCount - 1) {
        enemyId = currentPortalInfo.boss;
    } else {
        // Seleccionar enemigo normal al azar del listado
        enemyId = listEnemies[Math.floor(Math.random() * listEnemies.length)];
    }

    const overlay = document.getElementById('battle-overlay');
    overlay.classList.add('active');

    // Despejar logs de combate
    const logs = document.getElementById('battle-log-txt');
    logs.innerHTML = '';
    
    // Instanciar motor de batalla
    activeBattle = new window.BattleEngine(
        userState,
        // Calcular AP completo
        calculateAttackPower(userState.stats, userState.userClass, getEquippedItemsSync(), [], 0).ap,
        // Arma equipada
        getEquippedWeaponSync(),
        userState.userClass,
        enemyId,
        // Función Log
        (txt) => {
            const p = document.createElement('div');
            p.innerText = txt;
            logs.appendChild(p);
            logs.scrollTop = logs.scrollHeight;
        },
        // Función Actualización UI
        (engine) => {
            updateBattleUI(engine);
        }
    );

    activeBattle.start();
    setupBattleControls();
}

function getEquippedItemsSync() {
    // Retornar equipamiento síncrono del estado local del usuario (no persistido en DB pero listo en userState)
    // Para simplificar, buscaremos los IDs guardados en userState.equippedItems
    const items = [];
    userState.equippedItems.forEach(itemId => {
        const item = window.ITEMS_DATABASE[itemId];
        if (item) {
            items.push(item);
        }
    });
    return items;
}

function getEquippedWeaponSync() {
    const items = getEquippedItemsSync();
    return items.find(i => i.type === 'arma') || null;
}

function updateBattleUI(engine) {
    // Enemigo
    const enemyIconEl = document.getElementById('battle-enemy-gfx') || document.getElementById('enemy-icon-ui');
    if (enemyIconEl) enemyIconEl.innerText = engine.enemyIcon;

    const enemyNameEl = document.getElementById('enemy-name-ui');
    if (enemyNameEl) enemyNameEl.innerText = engine.enemyName;

    const enemyLvlEl = document.getElementById('enemy-lvl-ui');
    if (enemyLvlEl) enemyLvlEl.innerText = `LV ${engine.enemyLevel}`;
    
    const enemyHpPercent = Math.max(0, (engine.enemyHp / engine.enemyMaxHp) * 100);
    const enemyHpBar = document.getElementById('enemy-hp-bar');
    if (enemyHpBar) enemyHpBar.style.width = `${enemyHpPercent}%`;

    const enemyHpTxt = document.getElementById('enemy-hp-txt');
    if (enemyHpTxt) enemyHpTxt.innerText = `${Math.max(0, Math.round(engine.enemyHp))} / ${engine.enemyMaxHp} HP`;

    // Jugador
    const playerHpPercent = Math.max(0, (engine.playerHp / engine.playerMaxHp) * 100);
    const playerHpBar = document.getElementById('player-hp-bar');
    if (playerHpBar) playerHpBar.style.width = `${playerHpPercent}%`;

    const playerHpTxt = document.getElementById('player-hp-txt');
    if (playerHpTxt) playerHpTxt.innerText = `${Math.max(0, Math.round(engine.playerHp))} / ${Math.round(engine.playerMaxHp)} HP`;

    // Si terminó el combate
    if (engine.isOver) {
        document.getElementById('btn-action-attack').disabled = true;
        document.getElementById('btn-action-defend').disabled = true;
        document.getElementById('btn-action-item').disabled = true;

        const nextBtn = document.createElement('button');
        nextBtn.className = 'btn-massive';
        nextBtn.style.marginTop = '15px';
        nextBtn.innerText = engine.rewards ? 'Reclamar Recompensas' : 'Cerrar Portal';
        
        nextBtn.addEventListener('click', async () => {
            sounds.click();
            document.getElementById('battle-overlay').classList.remove('active');
            
            if (engine.rewards) {
                // Agregar oro, XP
                userState.gold += engine.rewards.gold;
                userState.xp += engine.rewards.xp;
                
                // Agregar loot
                for (const lootId of engine.rewards.loot) {
                    await addLootToInventory(lootId);
                }

                // Verificar nivel
                let levelUp = false;
                while (userState.xp >= window.getXPForLevel(userState.level)) {
                    userState.xp -= window.getXPForLevel(userState.level);
                    userState.level++;
                    levelUp = true;
                }
                
                if (levelUp) {
                    sounds.levelUp();
                    alert(`⭐ ¡HAS SUBIDO DE NIVEL! Ahora eres nivel ${userState.level}. El poder de tus atributos base se recalculará.`);
                }

                await saveUserProfile();

                // Continuar portal o finalizar
                currentPortalStage++;
                if (currentPortalStage < currentPortalInfo.battlesCount) {
                    if (confirm(`Combate completado con éxito. Pasas a la etapa ${currentPortalStage + 1} de ${currentPortalInfo.battlesCount}. ¿Deseas continuar?`)) {
                        launchPortalFight();
                    } else {
                        // Abandona portal voluntariamente
                        currentPortalInfo = null;
                        renderTabRPG();
                    }
                } else {
                    // Portal finalizado por completo
                    alert(`🏆 ¡Felicidades! Has completado con éxito la mazmorra "${currentPortalInfo.name}". Las sombras te reconocen como digno.`);
                    currentPortalInfo = null;
                    // Desbloquear logro
                    unlockAchievement('primer_portal');
                    renderTabRPG();
                }
            } else {
                // Derrota, se cierra el portal
                currentPortalInfo = null;
                renderTabRPG();
            }
        });

        // Insertar botón de acción siguiente
        document.getElementById('battle-log-txt').appendChild(nextBtn);
    }
}

function setupBattleControls() {
    const btnAttack = document.getElementById('btn-action-attack');
    const btnDefend = document.getElementById('btn-action-defend');
    const btnItem = document.getElementById('btn-action-item');

    btnAttack.disabled = false;
    btnDefend.disabled = false;
    btnItem.disabled = false;

    // Limpiar event listeners previos
    const newAttack = btnAttack.cloneNode(true);
    btnAttack.parentNode.replaceChild(newAttack, btnAttack);
    newAttack.addEventListener('click', () => {
        sounds.combatHit();
        activeBattle.playerAttack();
    });

    const newDefend = btnDefend.cloneNode(true);
    btnDefend.parentNode.replaceChild(newDefend, btnDefend);
    newDefend.addEventListener('click', () => {
        sounds.click();
        activeBattle.playerDefend();
    });

    const newItem = btnItem.cloneNode(true);
    btnItem.parentNode.replaceChild(newItem, btnItem);
    newItem.addEventListener('click', () => {
        sounds.click();
        openBattleItemSelection();
    });
}

async function openBattleItemSelection() {
    const overlay = document.getElementById('battle-items-modal');
    overlay.classList.add('active');

    const container = document.getElementById('battle-items-list');
    container.innerHTML = '';

    const inv = await window.dbInventory.getAll();
    const consumibles = inv.filter(i => i.type === 'consumible' && i.quantity > 0);

    if (consumibles.length === 0) {
        container.innerHTML = `<div style="text-align:center; padding:20px; color:rgba(255,255,255,0.4);">No tienes objetos consumibles en tu inventario.</div>`;
    } else {
        consumibles.forEach(item => {
            const card = document.createElement('div');
            card.className = `select-card`;
            card.addEventListener('click', () => {
                sounds.heal();
                closeModal('battle-items-modal');
                activeBattle.playerUseItem(item, async (consumed) => {
                    consumed.quantity--;
                    if (consumed.quantity <= 0) {
                        await window.dbInventory.delete(consumed.id);
                    } else {
                        await window.dbInventory.save(consumed);
                    }
                });
            });

            card.innerHTML = `
                <div class="select-card-icon">${item.icon}</div>
                <div class="select-card-info">
                    <div class="select-card-title">${item.name} (${item.quantity})</div>
                    <div class="select-card-desc">${item.desc}</div>
                </div>
            `;
            container.appendChild(card);
        });
    }

    document.getElementById('btn-close-battle-items').onclick = () => {
        sounds.click();
        closeModal('battle-items-modal');
    };
}

async function addLootToInventory(lootId) {
    const dbItem = window.ITEMS_DATABASE[lootId];
    if (!dbItem) return;

    const inv = await window.dbInventory.getAll();
    const existing = inv.find(i => i.itemId === lootId);

    if (existing) {
        existing.quantity++;
        await window.dbInventory.save(existing);
    } else {
        await window.dbInventory.save({
            itemId: lootId,
            name: dbItem.name,
            type: dbItem.type,
            rarity: dbItem.rarity,
            icon: dbItem.icon,
            desc: dbItem.desc,
            quantity: 1,
            equipped: false,
            stats: dbItem.stats ? { ...dbItem.stats } : null
        });
    }
}

// --------------------------------------------------------------------------
// 11. RENDERIZACIÓN PESTAÑA: INVENTARIO
// --------------------------------------------------------------------------
let activeInventoryTab = 'arma';

function renderTabInventory() {
    // Configurar tabs de inventario
    document.querySelectorAll('.inventory-tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            sounds.click();
            document.querySelectorAll('.inventory-tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            activeInventoryTab = btn.dataset.tab;
            loadInventoryGrid();
        });
    });

    loadInventoryGrid();
}

async function loadInventoryGrid() {
    const grid = document.getElementById('inventory-grid');
    grid.innerHTML = '';

    const inv = await window.dbInventory.getAll();
    const filtered = inv.filter(i => i.type === activeInventoryTab);

    // Crear 12 slots para dar apariencia de inventario RPG clásico
    const slotsCount = Math.max(12, Math.ceil(filtered.length / 4) * 4);
    
    for (let i = 0; i < slotsCount; i++) {
        const slot = document.createElement('div');
        
        if (i < filtered.length) {
            const item = filtered[i];
            slot.className = `inventory-slot rarity-${item.rarity}`;
            slot.innerHTML = `
                ${item.icon}
                ${item.quantity > 1 ? `<div class="inventory-slot-qty">${item.quantity}</div>` : ''}
                ${item.equipped ? `<div class="inventory-slot-equipped">E</div>` : ''}
            `;
            slot.addEventListener('click', () => {
                sounds.click();
                openItemDetailModal(item);
            });
        } else {
            slot.className = 'inventory-slot empty';
            slot.innerHTML = '';
        }
        grid.appendChild(slot);
    }
}

function openItemDetailModal(item) {
    const overlay = document.getElementById('item-detail-modal');
    overlay.classList.add('active');

    document.getElementById('lbl-item-name').innerText = item.name;
    document.getElementById('lbl-item-desc').innerText = item.desc;
    document.getElementById('lbl-item-rarity').innerText = `Rareza: ${item.rarity.replace('_', ' ').toUpperCase()}`;
    
    const statsBox = document.getElementById('item-stats-box');
    statsBox.innerHTML = '';
    
    if (item.stats) {
        if (item.stats.attack) {
            statsBox.innerHTML += `<div>Ataque base: +${item.stats.attack}</div>`;
        }
        if (item.stats.defense) {
            statsBox.innerHTML += `<div>Defensa base: +${item.stats.defense}</div>`;
        }
        if (item.stats.upgradeLevel > 0) {
            statsBox.innerHTML += `<div style="color:var(--color-success)">Nivel de mejora: +${item.stats.upgradeLevel}</div>`;
        }
    }

    const btnEquip = document.getElementById('btn-equip-item');
    const isEquippable = item.type === 'arma' || item.type === 'armadura';

    if (isEquippable) {
        btnEquip.style.display = 'block';
        btnEquip.innerText = item.equipped ? 'Desequipar' : 'Equipar';
        
        // Clonar para limpiar handlers
        const clone = btnEquip.cloneNode(true);
        btnEquip.parentNode.replaceChild(clone, btnEquip);
        
        clone.addEventListener('click', async () => {
            sounds.activation();
            if (item.equipped) {
                // Desequipar
                item.equipped = false;
                userState.equippedItems = userState.equippedItems.filter(id => id !== item.itemId);
            } else {
                // Equipar (primero desequipar otras del mismo tipo en BD)
                const all = await window.dbInventory.getAll();
                const equippedSameType = all.find(i => i.type === item.type && i.equipped);
                if (equippedSameType) {
                    equippedSameType.equipped = false;
                    await window.dbInventory.save(equippedSameType);
                    userState.equippedItems = userState.equippedItems.filter(id => id !== equippedSameType.itemId);
                }
                item.equipped = true;
                userState.equippedItems.push(item.itemId);
            }

            await window.dbInventory.save(item);
            await saveUserProfile();
            closeModal('item-detail-modal');
            loadInventoryGrid();
        });
    } else {
        btnEquip.style.display = 'none';
    }

    document.getElementById('btn-close-item-detail').onclick = () => {
        sounds.click();
        closeModal('item-detail-modal');
    };
}

// --------------------------------------------------------------------------
// 12. SISTEMA DE LOGROS Y CONFIGURACIÓN
// --------------------------------------------------------------------------
async function unlockAchievement(achievementId) {
    // Definir logros si están vacíos
    const achievementsList = [
        { id: 'primer_paso', name: 'Primer Paso', desc: 'Completaste el cuestionario de calibración inicial.', reward: '100 Oro', completed: true },
        { id: 'primer_portal', name: 'Explorador de Portales', desc: 'Completa con éxito un Portal Semanal.', reward: '250 Oro', completed: false },
        { id: 'constancia', name: 'Disciplina de Hierro', desc: 'Mantén una racha de 7 días consecutivos.', reward: 'Receta: Peto de Cuero', completed: false },
        { id: 'monarca', name: 'Poder de Monarca', desc: 'Alcanza el Nivel 50.', reward: 'Objeto: Daga de las Sombras', completed: false }
    ];

    try {
        const loaded = await window.dbAchievements.getAll();
        if (loaded.length === 0) {
            await window.dbAchievements.saveAll(achievementsList);
        }
        
        const target = await window.dbAchievements.getAll();
        const ach = target.find(a => a.id === achievementId);
        if (ach && !ach.completed) {
            ach.completed = true;
            await window.dbAchievements.save(ach);
            
            // Entregar recompensa
            if (achievementId === 'primer_portal') {
                userState.gold += 250;
            } else if (achievementId === 'constancia') {
                await addLootToInventory('receta_armadura_cuero');
            } else if (achievementId === 'monarca') {
                await addLootToInventory('daga_sombras');
            }
            await saveUserProfile();
            
            alert(`🏆 ¡LOGRO COMPLETADO! "${ach.name}": ${ach.desc}. Recibes recompensa.`);
        }
    } catch(e) {
        console.warn('Error logs:', e);
    }
}

async function unlockTitle(titleId) {
    if (!userState.unlockedTitles) {
        userState.unlockedTitles = [];
    }
    if (!userState.unlockedTitles.includes(titleId)) {
        userState.unlockedTitles.push(titleId);
        await saveUserProfile();
    }
}

// --------------------------------------------------------------------------
// 13. PANTALLA: TIENDA, CRAFTING Y MEJORAS
// --------------------------------------------------------------------------
let activeShopTab = 'comprar';

function renderTabShop() {
    showScreen('screen-shop');
    
    document.querySelectorAll('.shop-tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            sounds.click();
            document.querySelectorAll('.shop-tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            activeShopTab = btn.dataset.tab;
            loadShopTabContent();
        });
    });

    loadShopTabContent();
}

async function loadShopTabContent() {
    const grid = document.getElementById('shop-content-grid');
    grid.innerHTML = '';
    
    // Rellenar saldo de oro actual
    document.getElementById('shop-gold-balance').innerText = `Tus Fondos: ${userState.gold} Oro`;

    if (activeShopTab === 'comprar') {
        const itemsToBuy = [
            { id: 'pocion_peque', price: 50 },
            { id: 'pocion_grande', price: 150 },
            { id: 'antidoto', price: 40 },
            { id: 'bomba_fuego', price: 80 },
            { id: 'cristal_helado', price: 120 },
            { id: 'pergamino_electrico', price: 150 },
            { id: 'receta_espada_acero', price: 200 },
            { id: 'receta_armadura_cuero', price: 200 }
        ];

        itemsToBuy.forEach(shopItem => {
            const dbItem = window.ITEMS_DATABASE[shopItem.id];
            const card = document.createElement('div');
            card.className = 'shop-item-card';
            card.innerHTML = `
                <div>
                    <div class="shop-item-icon">${dbItem.icon}</div>
                    <div class="shop-item-title">${dbItem.name}</div>
                    <div class="shop-item-desc">${dbItem.desc}</div>
                </div>
                <div>
                    <div class="shop-item-price">🟡 ${shopItem.price} Oro</div>
                    <button class="btn-shop-buy" data-id="${shopItem.id}" data-price="${shopItem.price}">Comprar</button>
                </div>
            `;
            
            card.querySelector('.btn-shop-buy').addEventListener('click', (e) => {
                const id = e.target.dataset.id;
                const price = parseInt(e.target.dataset.price);
                buyItem(id, price);
            });
            grid.appendChild(card);
        });
    } else if (activeShopTab === 'forjar') {
        // Mostrar recetas desbloqueadas en el inventario del usuario para poder forjar
        const inv = await window.dbInventory.getAll();
        const recetas = inv.filter(i => i.type === 'receta');

        if (recetas.length === 0) {
            grid.innerHTML = `<div style="grid-column: 1/-1; text-align:center; padding:30px; color:rgba(255,255,255,0.4);">No tienes recetas de forja desbloqueadas. Puedes comprarlas en la pestaña COMPRAR o ganarlas derrotando Jefes.</div>`;
            return;
        }

        recetas.forEach(recetaItem => {
            const dbItem = window.ITEMS_DATABASE[recetaItem.itemId];
            const details = dbItem.recipe; // details = { target, materials: { hierro: 8 }, gold: 150 }
            const targetItem = window.ITEMS_DATABASE[details.target];

            const card = document.createElement('div');
            card.className = 'shop-item-card';
            
            // Formatear materiales requeridos
            let matText = '';
            Object.keys(details.materials).forEach(matId => {
                matText += `${window.ITEMS_DATABASE[matId].icon} ${details.materials[matId]} `;
            });

            card.innerHTML = `
                <div>
                    <div class="shop-item-icon">${targetItem.icon}</div>
                    <div class="shop-item-title">${targetItem.name}</div>
                    <div class="shop-item-desc" style="font-size:11px; height:auto;">Requisitos: ${matText}<br>🟡 ${details.gold} Oro</div>
                </div>
                <div>
                    <button class="btn-shop-buy" style="border-color:var(--color-secondary)" data-id="${recetaItem.itemId}">Forjar</button>
                </div>
            `;
            
            card.querySelector('.btn-shop-buy').addEventListener('click', () => {
                forgeItem(details);
            });
            grid.appendChild(card);
        });
    }
}

async function buyItem(itemId, price) {
    if (userState.gold < price) {
        alert('❌ No tienes suficiente Oro.');
        return;
    }

    sounds.levelUp();
    userState.gold -= price;
    await addLootToInventory(itemId);
    await saveUserProfile();
    loadShopTabContent();
    alert(`✅ Comprado con éxito.`);
}

async function forgeItem(recipeDetails) {
    // recipeDetails = { target, materials: { hierro: 8 }, gold: 150 }
    if (userState.gold < recipeDetails.gold) {
        alert('❌ No tienes suficiente Oro para la forja.');
        return;
    }

    const inv = await window.dbInventory.getAll();
    
    // Verificar si se poseen todos los materiales en cantidades adecuadas
    let hasMats = true;
    const matsToModify = [];

    for (const matId of Object.keys(recipeDetails.materials)) {
        const requiredQty = recipeDetails.materials[matId];
        const owned = inv.find(i => i.itemId === matId);
        
        if (!owned || owned.quantity < requiredQty) {
            hasMats = false;
            break;
        } else {
            matsToModify.push({ item: owned, deduct: requiredQty });
        }
    }

    if (!hasMats) {
        alert('❌ No tienes todos los materiales requeridos para la forja.');
        return;
    }

    // Efectos de sonido y martillo
    sounds.activation();
    userState.gold -= recipeDetails.gold;

    // Descontar materiales
    for (const mod of matsToModify) {
        mod.item.quantity -= mod.deduct;
        if (mod.item.quantity <= 0) {
            await window.dbInventory.delete(mod.item.id);
        } else {
            await window.dbInventory.save(mod.item);
        }
    }

    // Agregar objeto forjado
    await addLootToInventory(recipeDetails.target);
    await saveUserProfile();
    
    loadShopTabContent();
    alert(`🔨 ¡FORJA EXITOSA! Has creado ${window.ITEMS_DATABASE[recipeDetails.target].name}.`);
}

// --------------------------------------------------------------------------
// 14. CONFIGURACIÓN MODAL
// --------------------------------------------------------------------------
function openSettingsModal() {
    const overlay = document.getElementById('settings-modal');
    overlay.classList.add('active');

    // Rellenar toggles basados en el estado
    document.getElementById('toggle-scaling').checked = userState.settings.scalingEnabled;
    document.getElementById('toggle-pause').checked = userState.settings.pauseAllowed;
    
    document.getElementById('toggle-scaling').onclick = async (e) => {
        sounds.click();
        userState.settings.scalingEnabled = e.target.checked;
        await saveUserProfile();
    };

    document.getElementById('toggle-pause').onclick = async (e) => {
        sounds.click();
        userState.settings.pauseAllowed = e.target.checked;
        await saveUserProfile();
    };
}

// --------------------------------------------------------------------------
// 15. RESET DIARIO Y CHEQUEOS DE INACTIVIDAD
// --------------------------------------------------------------------------
async function checkAndApplyDailyReset() {
    const todayStr = new Date().toISOString().split('T')[0];
    
    if (userState.lastLoginDate !== todayStr) {
        sounds.activation();
        
        // Evaluar inactividad para modo recuperación
        const recMission = window.checkRecoveryMode(userState.lastLoginDate);
        if (recMission) {
            await window.dbMissions.save(recMission);
            alert('⚠️ ADVERTENCIA: Has estado inactivo durante varios días. El Sistema ha activado el MODO RECUPERACIÓN. Completa la misión especial para restaurar tu ritmo.');
        } else {
            // Aumentar días de actividad acumulados
            userState.daysActive++;
        }

        // Generar las nuevas misiones del día recomendadas
        const primaryGoal = tempCalibrationData.goal || 'fisico';
        const newMissions = window.generateDailyMissions(primaryGoal, userState.level);
        
        // Guardar misiones
        for (const mission of newMissions) {
            await window.dbMissions.save(mission);
        }

        // Actualizar último inicio
        userState.lastLoginDate = todayStr;
        await saveUserProfile();
    }
}

// --------------------------------------------------------------------------
// 16. PERSISTENCIA AUXILIAR
// --------------------------------------------------------------------------
async function saveUserProfile() {
    try {
        await window.dbSettings.set('user_profile', userState);
    } catch(e) {
        console.warn('Error guardando perfil:', e);
    }
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

// Exportar funciones útiles a nivel global
window.showScreen = showScreen;
window.renderTabHome = renderTabHome;
window.renderTabMissions = renderTabMissions;
window.renderTabRPG = renderTabRPG;
window.renderTabInventory = renderTabInventory;
window.renderTabProfile = renderTabProfile;
window.renderTabProfileStats = renderTabProfileStats;
window.renderTabShop = renderTabShop;
window.sounds = sounds;
console.log('App manager (app.js) cargado correctamente.');
