<script>
    (() => {
        const storageKey = 'cosrent-theme';
        let storedTheme = null;

        try {
            storedTheme = window.localStorage.getItem(storageKey);
        } catch {
            storedTheme = null;
        }

        const systemPrefersDark = window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false;
        const theme = storedTheme === 'light' || storedTheme === 'dark'
            ? storedTheme
            : (systemPrefersDark ? 'dark' : 'light');
        const root = document.documentElement;

        root.classList.toggle('dark', theme === 'dark');
        root.dataset.theme = theme;
        root.dataset.themeSource = storedTheme === 'light' || storedTheme === 'dark' ? 'manual' : 'system';
    })();
</script>
