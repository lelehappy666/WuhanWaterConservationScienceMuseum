import { useEffect, useCallback } from 'react';
import { useVideoStore } from '../store';
import { fetchVideos } from '../utils/service';
import { useInView } from 'react-intersection-observer';

export const useVideos = () => {
  const {
    videos,
    loading,
    error,
    page,
    hasMore,
    searchQuery,
    setVideos,
    addVideos,
    setLoading,
    setError,
    setPage,
    setHasMore,
  } = useVideoStore();

  const [ref, inView] = useInView({
    threshold: 0,
    rootMargin: '100px',
  });

  const loadVideos = useCallback(async (pageNum: number, search: string, isRefresh = false) => {
    // Prevent multiple calls if already loading
    setLoading(true);
    setError(null);
    
    try {
      const { data, total } = await fetchVideos(pageNum, 20, search);
      
      if (isRefresh || pageNum === 1) {
        setVideos(data);
      } else {
        addVideos(data);
      }
      
      setHasMore(data.length > 0 && (isRefresh ? data.length : videos.length + data.length) < total);
    } catch (error: any) {
      console.error("Failed to load videos", error);
      setError(error.message || "Failed to load videos");
      // CRITICAL: Stop infinite loop on error by setting hasMore to false
      // This prevents the useEffect from firing again immediately
      setHasMore(false);
    } finally {
      setLoading(false);
    }
  }, []); // Removed dependencies to avoid recreating function unnecessarily

  // Initial load or search change
  useEffect(() => {
    // Reset page and load immediately
    setPage(1);
    // We pass page 1 directly to ensure we load the first page
    loadVideos(1, searchQuery, true);
  }, [searchQuery]); 

  // Infinite scroll
  useEffect(() => {
    // Only load next page if:
    // 1. Element is in view
    // 2. We have more data
    // 3. Not currently loading
    // 4. No error occurred (implicit via hasMore=false on error, but let's be safe)
    if (inView && hasMore && !loading && !error) {
      const nextPage = page + 1;
      setPage(nextPage);
      loadVideos(nextPage, searchQuery);
    }
  }, [inView, hasMore, loading, page, searchQuery, error]);

  return {
    videos,
    loading,
    error,
    hasMore,
    ref
  };
};
