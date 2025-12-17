import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Layout } from '../components/Layout';
import { fetchVideoById, connectAndSendPlayInstruction, connectLoginOnly } from '../utils/service';
import { Video } from '../utils/types';
import { PageLoading } from '../components/Loading';
import { Calendar, Clock, Play, Share2, Heart } from 'lucide-react';
import { motion } from 'framer-motion';

export const VideoDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [video, setVideo] = useState<Video | null>(null);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [sendMsg, setSendMsg] = useState<string | null>(null);

  useEffect(() => {
    const loadVideo = async () => {
      if (id) {
        setLoading(true);
        const data = await fetchVideoById(id);
        setVideo(data);
        setLoading(false);
      }
    };
    loadVideo();
  }, [id]);

  if (loading) {
    return (
      <Layout title="视频详情" showBack>
        <PageLoading />
      </Layout>
    );
  }

  if (!video) {
    return (
      <Layout title="视频详情" showBack>
        <div className="text-center py-20 text-ios-subtext">
          <p>未找到该影片</p>
          <div className="mt-6 flex items-center justify-center space-x-3">
            <button
              className=""
              onClick={async () => {
                if (sending) return;
                setSending(true);
                setSendMsg(null);
                try {
                  const res = await connectLoginOnly();
                  if ((res as any)?.code === 0) {
                    setSendMsg('登录成功');
                  } else {
                    const msg = (res as any)?.message || '登录失败';
                    setSendMsg(msg);
                  }
                } catch (e: any) {
                  setSendMsg(e?.message || '登录失败');
                } finally {
                  setSending(false);
                }
              }}
              disabled={sending}
            >
              {sending ? '正在连接...' : '登录'}
            </button>
            {sendMsg && <div>{sendMsg}</div>}
          </div>
        </div>
      </Layout>
    );
  }

  const actions = (
    <>
      <button className="p-2 rounded-full hover:bg-gray-100">
        <Heart className="w-6 h-6 text-ios-text" />
      </button>
      <button className="p-2 rounded-full hover:bg-gray-100">
        <Share2 className="w-6 h-6 text-ios-text" />
      </button>
    </>
  );

  return (
    <Layout title="视频详情" showBack actions={actions}>
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="max-w-4xl mx-auto"
      >
        {/* Hero Image / Player Placeholder */}
        <div className="relative aspect-video rounded-ios-lg overflow-hidden bg-black shadow-ios-lg mb-6 group cursor-pointer">
          <img 
            src={video.URL} 
            alt={video.Name} 
            className="w-full h-full object-cover opacity-80 group-hover:opacity-60 transition-opacity duration-300"
          />
          <div className="absolute inset-0 flex items-center justify-center">
             <div className="w-16 h-16 bg-white/20 backdrop-blur-md rounded-full flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                <Play className="w-8 h-8 text-white fill-current ml-1" />
             </div>
          </div>
        </div>

        {/* Info Card */}
        <div className="bg-white rounded-ios shadow-ios p-6 mb-6">
          <h1 className="text-2xl font-bold text-ios-text mb-4">{video.Name}</h1>
          
          <div className="flex items-center space-x-4 text-sm text-ios-subtext mb-6 pb-6 border-b border-gray-100">
            <div className="flex items-center">
              <Calendar className="w-4 h-4 mr-1.5" />
              <span>{video.Year || video.Time}</span>
            </div>
            {/* Only show clock if Time is different from Year (meaning it might be duration) */}
            {video.Time && video.Time !== video.Year && (
                <div className="flex items-center">
                  <Clock className="w-4 h-4 mr-1.5" />
                  <span>{video.Time}</span>
                </div>
            )}
             <div className="flex items-center">
              <span>发布时间</span>
            </div>
          </div>

          <div>
            <h3 className="text-lg font-bold text-ios-text mb-3">视频简介</h3>
            <p className="text-gray-600 leading-relaxed text-justify">
              {video.Info}
            </p>
          </div>

          {/* Play Button */}
          <div className="mt-6 flex items-center justify-start space-x-3">
            <button
              className=""
              onClick={async () => {
                if (sending) return;
                setSending(true);
                setSendMsg(null);
                try {
                  const res = await connectLoginOnly();
                  if ((res as any)?.code === 0) {
                    setSendMsg('登录成功');
                  } else {
                    const msg = (res as any)?.message || '登录失败';
                    setSendMsg(msg);
                  }
                } catch (e: any) {
                  setSendMsg(e?.message || '登录失败');
                } finally {
                  setSending(false);
                }
              }}
              disabled={sending}
            >
              {sending ? '正在连接...' : '登录'}
            </button>
            {sendMsg && <div>{sendMsg}</div>}
          </div>
        </div>
      </motion.div>
    </Layout>
  );
};
