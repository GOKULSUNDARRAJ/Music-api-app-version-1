const express = require('express');
const router = express.Router();
const playlistController = require('../controllers/playlistController');
const { requireUserAuth } = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configure Cloudinary (re-uses config if already set in other files, but safe to set again)
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Configure multer for playlist image uploads
const storage = process.env.CLOUDINARY_CLOUD_NAME ? new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'music_app_playlists',
    resource_type: 'image',
    public_id: (req, file) => Date.now() + '-' + Math.round(Math.random() * 1e9),
  }
}) : multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

// Smart middleware: supports both multipart/form-data AND raw JSON
const formParser = multer().none();
const smartParser = (req, res, next) => {
  const ct = req.headers['content-type'] || '';
  if (ct.includes('multipart/form-data')) {
    // If it's a creation request, we expect a file
    if (req.path === '/create') {
      return upload.single('image')(req, res, next);
    }
    return formParser(req, res, next);
  }
  return next();
};

router.use(requireUserAuth);

// Create a named playlist
router.post('/create', upload.single('image'), playlistController.createPlaylist);

// Add item to a specific playlist
router.post('/add-item', smartParser, playlistController.addItemToPlaylist);

// List all user playlists (for the main playlist tab)
router.get('/list', playlistController.getPlaylistList);

// Simple list for dialogs
router.get('/list-simple', playlistController.getPlaylistSimple);

// Legacy Toggle (Adds to a "My Favorites" default playlist)
router.post('/toggle', smartParser, playlistController.togglePlaylistLegacy);

// Toggle item in default "My Playlist"
router.post('/toggle-my', smartParser, playlistController.toggleMyPlaylist);
router.post('/AddToMyPlayList', smartParser, playlistController.toggleMyPlaylist); // Exact name requested

// Get "My Playlist" items in Sections format
router.get('/my', playlistController.getMyPlaylist);

// Get user playlists as categories
router.get('/user-categories', playlistController.getPlaylistCategories);

// Check if item is in "My Playlist" (Legacy)
router.get('/status/:playlistId', playlistController.checkPlaylistStatus);

// Get items in a specific playlist
router.get('/items/:playlistId', playlistController.getPlaylistItems);
router.get('/playlists/:playlistId/items', playlistController.getPlaylistItems); // Plural alias

// Check if item is in a specific playlist (Generic)
// Note: This is now redundant but kept for absolute route matching if needed
// Actually, I'll just keep the one /status/:playlistId as it covers both.

router.delete('/all', playlistController.deleteAllPlaylists);
router.delete('/:playlistId', playlistController.deletePlaylist);

module.exports = router;
