import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Calendar, PlayCircle } from 'lucide-react';
import { Video } from '../utils/types';
import { Link } from 'react-router-dom';

interface VideoCardProps {
  video: Video;
}

export const VideoCard: React.FC<VideoCardProps> = ({ video }) => {
  const [imageLoaded, setImageLoaded] = useState(false);

  return (
    <Link to={`/video/${video._id}`}>
      <motion.div
        className="bg-ios-card rounded-ios shadow-ios overflow-hidden cursor-pointer group h-full flex flex-col"
        whileHover={{ scale: 1.02, y: -2 }}
        whileTap={{ scale: 0.98 }}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
      >
        <div className="relative aspect-video bg-gray-200 overflow-hidden">
          {!imageLoaded && (
            <div className="absolute inset-0 animate-pulse bg-gray-300" />
          )}
          <img
            src={video.URL}
            alt={video.Name}
            loading="lazy"
            className={`w-full h-full object-cover transition-opacity duration-500 ${
              imageLoaded ? 'opacity-100' : 'opacity-0'
            }`}
            onLoad={() => setImageLoaded(true)}
          />
          <div className="absolute inset-0 bg-black/10 group-hover:bg-black/20 transition-colors duration-300 flex items-center justify-center">
            <PlayCircle className="text-white opacity-0 group-hover:opacity-100 transform scale-75 group-hover:scale-100 transition-all duration-300 w-12 h-12" />
          </div>
          {/* Badge: Use Time as Year if available, since DB Time field seems to hold the year 2025 */}
          {(video.Year || video.Time) && (
             <div className="absolute top-2 right-2 bg-black/60 backdrop-blur-md text-white text-xs px-2 py-1 rounded-full font-medium">
               {video.Year || video.Time}
             </div>
          )}
          {/* If there was a separate duration field, we would display it here. 
              But based on OCR, Time is 2025. We'll hide the second badge if it's duplicate or missing.
              For now, we only show one badge if Time and Year are the same or Year is missing.
          */}
        </div>
        
        <div className="p-4 flex flex-col flex-grow">
          <h3 className="text-lg font-bold text-ios-text mb-2 line-clamp-1">{video.Name}</h3>
          <p className="text-sm text-ios-subtext line-clamp-2 mb-4 flex-grow">{video.Info}</p>
          
          <div className="flex items-center text-xs text-ios-subtext mt-auto">
             <Calendar className="w-3 h-3 mr-1" />
             <span>{video.Year || video.Time}年</span>
          </div>
        </div>
      </motion.div>
    </Link>
  );
};
