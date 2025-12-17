export interface Video {
  _id: string;
  Name: string;
  Time: string | number;
  Info: string;
  URL: string;
  // Year might not exist in the new DB schema based on OCR, but we keep it optional just in case
  Year?: string | number;
  createdAt?: string;
}

export interface VideoState {
  videos: Video[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  page: number;
}
