import { create } from 'zustand';
import { Video } from '../utils/types';

interface VideoStore {
  videos: Video[];
  loading: boolean;
  error: string | null;
  page: number;
  hasMore: boolean;
  searchQuery: string;
  
  setVideos: (videos: Video[]) => void;
  addVideos: (videos: Video[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setPage: (page: number) => void;
  setHasMore: (hasMore: boolean) => void;
  setSearchQuery: (query: string) => void;
  reset: () => void;
}

export const useVideoStore = create<VideoStore>((set) => ({
  videos: [],
  loading: false,
  error: null,
  page: 1,
  hasMore: true,
  searchQuery: '',

  setVideos: (videos) => set({ videos, error: null }),
  addVideos: (newVideos) => set((state) => ({ videos: [...state.videos, ...newVideos], error: null })),
  setLoading: (loading) => set({ loading }),
  setError: (error) => set({ error }),
  setPage: (page) => set({ page }),
  setHasMore: (hasMore) => set({ hasMore }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  reset: () => set({ videos: [], page: 1, hasMore: true, searchQuery: '', error: null }),
}));
