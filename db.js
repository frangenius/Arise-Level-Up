// db.js - Gestión de Base de Datos Local con IndexedDB para LEVEL UP
const DB_NAME = 'LevelUpDB';
const DB_VERSION = 2;

let dbPromise = null;

function initDB() {
    if (dbPromise) return dbPromise;

    dbPromise = new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);

        request.onupgradeneeded = (event) => {
            const db = event.target.result;

            // Almacén para configuraciones globales y perfil del usuario
            if (!db.objectStoreNames.contains('settings')) {
                db.createObjectStore('settings', { keyPath: 'key' });
            }

            // Almacén para misiones
            if (!db.objectStoreNames.contains('missions')) {
                db.createObjectStore('missions', { keyPath: 'id', autoIncrement: true });
            }

            // Almacén para el inventario de objetos
            if (!db.objectStoreNames.contains('inventory')) {
                db.createObjectStore('inventory', { keyPath: 'id', autoIncrement: true });
            }

            // Almacén para el historial de atributos (+2 Strength, etc.)
            if (!db.objectStoreNames.contains('history')) {
                db.createObjectStore('history', { keyPath: 'id', autoIncrement: true });
            }

            // Almacén para el calendario (formato fecha YYYY-MM-DD como clave)
            if (!db.objectStoreNames.contains('calendar')) {
                db.createObjectStore('calendar', { keyPath: 'date' });
            }

            // Almacén para logros
            if (!db.objectStoreNames.contains('achievements')) {
                db.createObjectStore('achievements', { keyPath: 'id' });
            }

            // Almacén para plantillas de rutina fija diaria del usuario
            if (!db.objectStoreNames.contains('routine_templates')) {
                db.createObjectStore('routine_templates', { keyPath: 'id', autoIncrement: true });
            }
        };

        request.onsuccess = (event) => {
            resolve(event.target.result);
        };

        request.onerror = (event) => {
            console.error('Error al abrir la base de datos:', event.target.error);
            reject(event.target.error);
        };
    });

    return dbPromise;
}

// Funciones genéricas de acceso a datos
async function getStore(storeName, mode = 'readonly') {
    const db = await initDB();
    const transaction = db.transaction(storeName, mode);
    return transaction.objectStore(storeName);
}

// Operaciones para SETTINGS (Perfil, estado global, configuración)
const dbSettings = {
    async get(key, defaultValue = null) {
        const store = await getStore('settings');
        return new Promise((resolve) => {
            const request = store.get(key);
            request.onsuccess = () => resolve(request.result ? request.result.value : defaultValue);
            request.onerror = () => resolve(defaultValue);
        });
    },

    async set(key, value) {
        const store = await getStore('settings', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.put({ key, value });
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    },

    async delete(key) {
        const store = await getStore('settings', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.delete(key);
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }
};

// Operaciones para MISIONES
const dbMissions = {
    async getAll() {
        const store = await getStore('missions');
        return new Promise((resolve) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result || []);
            request.onerror = () => resolve([]);
        });
    },

    async getById(id) {
        const store = await getStore('missions');
        return new Promise((resolve) => {
            const request = store.get(id);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => resolve(null);
        });
    },

    async save(mission) {
        const store = await getStore('missions', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.put(mission);
            request.onsuccess = () => resolve(request.result); // retorna el ID autogenerado o modificado
            request.onerror = () => reject(request.error);
        });
    },

    async delete(id) {
        const store = await getStore('missions', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.delete(id);
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    },

    async clear() {
        const store = await getStore('missions', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.clear();
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }
};

// Operaciones para INVENTARIO
const dbInventory = {
    async getAll() {
        const store = await getStore('inventory');
        return new Promise((resolve) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result || []);
            request.onerror = () => resolve([]);
        });
    },

    async save(item) {
        const store = await getStore('inventory', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.put(item);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    },

    async delete(id) {
        const store = await getStore('inventory', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.delete(id);
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    },

    async clear() {
        const store = await getStore('inventory', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.clear();
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }
};

// Operaciones para HISTORIAL DE ATRIBUTOS
const dbHistory = {
    async getAll() {
        const store = await getStore('history');
        return new Promise((resolve) => {
            const request = store.getAll();
            request.onsuccess = () => {
                // Ordenar por fecha o ID descendente para mostrar lo más reciente primero
                const result = request.result || [];
                result.sort((a, b) => b.id - a.id);
                resolve(result);
            };
            request.onerror = () => resolve([]);
        });
    },

    async add(entry) {
        // entry = { date: 'YYYY-MM-DD', text: '+2 Strength', attribute: 'strength', value: 2, timestamp: Date.now() }
        const store = await getStore('history', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.add(entry);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    },

    async clear() {
        const store = await getStore('history', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.clear();
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }
};

// Operaciones para CALENDARIO
const dbCalendar = {
    async getAll() {
        const store = await getStore('calendar');
        return new Promise((resolve) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result || []);
            request.onerror = () => resolve([]);
        });
    },

    async save(dayEntry) {
        // dayEntry = { date: 'YYYY-MM-DD', status: 'green'|'blue'|'red', xp: 120, hours: 2.5, stats: { strength: 1 } }
        const store = await getStore('calendar', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.put(dayEntry);
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    },

    async getByDate(date) {
        const store = await getStore('calendar');
        return new Promise((resolve) => {
            const request = store.get(date);
            request.onsuccess = () => resolve(request.result || null);
            request.onerror = () => resolve(null);
        });
    }
};

// Operaciones para LOGROS
const dbAchievements = {
    async getAll() {
        const store = await getStore('achievements');
        return new Promise((resolve) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result || []);
            request.onerror = () => resolve([]);
        });
    },

    async save(achievement) {
        const store = await getStore('achievements', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.put(achievement);
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    },

    async saveAll(achievementsList) {
        const db = await initDB();
        const transaction = db.transaction('achievements', 'readwrite');
        const store = transaction.objectStore('achievements');
        return new Promise((resolve, reject) => {
            achievementsList.forEach(ach => {
                store.put(ach);
            });
            transaction.oncomplete = () => resolve(true);
            transaction.onerror = () => reject(transaction.error);
        });
    }
};

// Operaciones para PLANTILLAS DE RUTINA DIARIA
const dbRoutineTemplates = {
    async getAll() {
        const store = await getStore('routine_templates');
        return new Promise((resolve) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result || []);
            request.onerror = () => resolve([]);
        });
    },

    async save(template) {
        const store = await getStore('routine_templates', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.put(template);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    },

    async saveAll(templatesList) {
        const db = await initDB();
        const transaction = db.transaction('routine_templates', 'readwrite');
        const store = transaction.objectStore('routine_templates');
        return new Promise((resolve, reject) => {
            templatesList.forEach(t => {
                store.put(t);
            });
            transaction.oncomplete = () => resolve(true);
            transaction.onerror = () => reject(transaction.error);
        });
    },

    async delete(id) {
        const store = await getStore('routine_templates', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.delete(id);
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    },

    async clear() {
        const store = await getStore('routine_templates', 'readwrite');
        return new Promise((resolve, reject) => {
            const request = store.clear();
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }
};

// Exportar base de datos
window.dbSettings = dbSettings;
window.dbMissions = dbMissions;
window.dbInventory = dbInventory;
window.dbHistory = dbHistory;
window.dbCalendar = dbCalendar;
window.dbAchievements = dbAchievements;
window.dbRoutineTemplates = dbRoutineTemplates;
window.initDB = initDB;
console.log('Database helper (db.js) cargado correctamente.');
