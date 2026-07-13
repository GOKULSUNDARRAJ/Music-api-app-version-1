const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const CollaborativePlaylistSong = sequelize.define('CollaborativePlaylistSong', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  playlistId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  songId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  addedById: {
    type: DataTypes.INTEGER,
    allowNull: false
  }
}, {
  tableName: 'collaborative_playlist_songs',
  timestamps: true,
  indexes: [
    {
      unique: true,
      fields: ['playlistId', 'songId']
    }
  ]
});

module.exports = CollaborativePlaylistSong;
