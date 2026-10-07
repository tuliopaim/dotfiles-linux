import { Cache, showToast, Toast } from "@vicinae/api";
import { useEffect, useState } from "react";

interface Loaded<T> {
  data?: T;
  error?: string;
  isLoading: boolean;
}

const cache = new Cache();

/** Shows the last cached value immediately, then replaces it with a fresh load. */
export function useCachedLoad<T>(key: string, load: () => Promise<T>, reloads: number): Loaded<T> {
  const [state, setState] = useState<Loaded<T>>(() => {
    const raw = cache.get(key);
    return { data: raw === undefined ? undefined : (JSON.parse(raw) as T), isLoading: true };
  });

  useEffect(() => {
    let cancelled = false;
    setState((previous) => ({ ...previous, error: undefined, isLoading: true }));

    load()
      .then((data) => {
        if (cancelled) return;
        cache.set(key, JSON.stringify(data));
        setState({ data, isLoading: false });
      })
      .catch((error: Error) => {
        if (cancelled) return;
        setState((previous) => ({ ...previous, error: error.message, isLoading: false }));
        // With nothing cached the list shows the error itself; otherwise say the list is out of date.
        if (cache.has(key)) showToast({ style: Toast.Style.Failure, title: "Refresh failed", message: error.message });
      });

    return () => {
      cancelled = true;
    };
  }, [key, reloads]);

  return state;
}
