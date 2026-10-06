import Alpine from 'alpinejs';

const themeStorageKey = 'cosrent-theme';

const getStoredTheme = () => {
    try {
        const storedTheme = window.localStorage.getItem(themeStorageKey);

        return storedTheme === 'light' || storedTheme === 'dark' ? storedTheme : null;
    } catch {
        return null;
    }
};

const getSystemTheme = () => (
    window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
);

const syncThemeToggles = (theme) => {
    document.querySelectorAll('[data-theme-toggle]').forEach((button) => {
        button.setAttribute('aria-pressed', String(theme === 'dark'));
    });
};

const applyTheme = (theme, source) => {
    const root = document.documentElement;

    root.classList.toggle('dark', theme === 'dark');
    root.dataset.theme = theme;
    root.dataset.themeSource = source;
    syncThemeToggles(theme);
};

const initializeThemeToggle = () => {
    const storedTheme = getStoredTheme();
    const systemTheme = getSystemTheme();

    applyTheme(storedTheme ?? systemTheme, storedTheme ? 'manual' : 'system');

    document.querySelectorAll('[data-theme-toggle]').forEach((button) => {
        button.addEventListener('click', () => {
            const nextTheme = document.documentElement.classList.contains('dark') ? 'light' : 'dark';

            try {
                window.localStorage.setItem(themeStorageKey, nextTheme);
            } catch {
                // The selected theme still applies when browser storage is unavailable.
            }

            applyTheme(nextTheme, 'manual');
        });
    });

    window.matchMedia?.('(prefers-color-scheme: dark)').addEventListener?.('change', (event) => {
        if (getStoredTheme() === null) {
            applyTheme(event.matches ? 'dark' : 'light', 'system');
        }
    });
};

const formatFileSize = (bytes) => {
    if (!Number.isFinite(bytes) || bytes <= 0) {
        return '0 KB';
    }

    const units = ['B', 'KB', 'MB', 'GB'];
    const exponent = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
    const value = bytes / (1024 ** exponent);

    return `${value.toFixed(value >= 10 || exponent === 0 ? 0 : 1)} ${units[exponent]}`;
};

Alpine.data('mediaPicker', ({
    maxFiles = 0,
    maxSizeMb = 0,
    kind = 'image',
    initialCount = 0,
    labels = {},
} = {}) => ({
    maxFiles,
    maxSizeMb,
    kind,
    initialCount,
    labels,
    files: [],
    dragging: false,
    notice: '',

    init() {
        this.$watch('files', () => this.syncInput());
        this.$root.addEventListener('change', (event) => {
            if (event.target.matches('input[type="checkbox"][name^="remove_"]')) {
                this.refreshSaved();
            }
        });
    },

    refreshSaved() {
        const boxes = Array.from(this.$root.querySelectorAll('input[type="checkbox"][name^="remove_"]'));

        this.initialCount = boxes.filter((box) => !box.checked).length;
    },

    get total() {
        return this.initialCount + this.files.length;
    },

    get remaining() {
        return Math.max(this.maxFiles - this.total, 0);
    },

    get isFull() {
        return this.remaining === 0;
    },

    get hasFiles() {
        return this.files.length > 0;
    },

    get accept() {
        return this.kind === 'video' ? 'video/mp4,video/quicktime,video/webm' : 'image/jpeg,image/png,image/webp';
    },

    open() {
        this.$refs.input.click();
    },

    add(fileList) {
        this.notice = '';
        this.dragging = false;

        const incoming = Array.from(fileList ?? []);

        if (incoming.length === 0) {
            return;
        }

        if (this.isFull) {
            this.notice = this.labels.limitReached;

            return;
        }

        const accepted = [];
        let rejected = null;

        for (const file of incoming) {
            if (accepted.length >= this.remaining) {
                rejected = this.labels.limitReached;
                break;
            }

            if (file.type !== '' && !file.type.startsWith(`${this.kind}/`)) {
                rejected = this.labels.invalidType.replace(':name', file.name);
                continue;
            }

            if (this.maxSizeMb > 0 && file.size > this.maxSizeMb * 1024 * 1024) {
                rejected = this.labels.tooLarge
                    .replace(':name', file.name)
                    .replace(':max', String(this.maxSizeMb));
                continue;
            }

            accepted.push({
                name: file.name,
                size: formatFileSize(file.size),
                url: URL.createObjectURL(file),
                raw: file,
            });
        }

        this.files = [...this.files, ...accepted];

        if (rejected !== null) {
            this.notice = rejected;
        }
    },

    remove(index) {
        URL.revokeObjectURL(this.files[index].url);
        this.files.splice(index, 1);
    },

    drop(event) {
        this.add(event.dataTransfer?.files);
    },

    clear() {
        this.files.forEach((file) => URL.revokeObjectURL(file.url));
        this.files = [];
        this.notice = '';
    },

    syncInput() {
        const transfer = new DataTransfer();

        this.files.forEach((file) => transfer.items.add(file.raw));

        this.$refs.input.files = transfer.files;
    },

    destroy() {
        this.files.forEach((file) => URL.revokeObjectURL(file.url));
    },
}));

window.Alpine = Alpine;
Alpine.start();

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeThemeToggle, { once: true });
} else {
    initializeThemeToggle();
}