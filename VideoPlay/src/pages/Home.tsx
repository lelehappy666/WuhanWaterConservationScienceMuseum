import React from 'react';
import { Layout } from '../components/Layout';
import { SearchBar } from '../components/SearchBar';
import { VideoCard } from '../components/VideoCard';
import { Loading } from '../components/Loading';
import { useVideos } from '../hooks/useVideos';
import { useVideoStore } from '../store';
import { motion } from 'framer-motion';

export const Home: React.FC = () => {
  const { videos, loading, error, hasMore, ref } = useVideos();
  const { searchQuery, setSearchQuery } = useVideoStore();

  return (
    <Layout title="视频资料库">
      <div className="max-w-7xl mx-auto">
        <SearchBar 
          value={searchQuery}
          onChange={setSearchQuery}
          onSearch={() => {}} // Debounced/Effect handled in hook
        />

        {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-ios mb-6">
                <p className="font-bold text-sm">加载失败</p>
                <p className="text-xs mt-1">{error}</p>
                <p className="text-xs mt-1 text-gray-500">请检查网络或刷新重试</p>
            </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {videos.map((video) => (
            <VideoCard key={video._id} video={video} />
          ))}
        </div>

        {videos.length === 0 && !loading && !error && (
          <div className="text-center py-20 text-ios-subtext">
            <p>暂无影片</p>
          </div>
        )}

        <div ref={ref} className="py-8">
          {loading && <Loading />}
          {!hasMore && videos.length > 0 && (
            <div className="text-center text-sm text-ios-subtext">
              没有更多了
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
};
