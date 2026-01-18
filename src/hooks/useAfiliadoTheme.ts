import { useEffect } from 'react';
import { useTheme } from 'next-themes';

export function useAfiliadoTheme() {
  const { setTheme } = useTheme();

  useEffect(() => {
    setTheme('light');
  }, [setTheme]);
}
