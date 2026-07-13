const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const CollaborativePlaylistUser = sequelize.define('CollaborativePlaylistUser', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  playlistId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false
  }
}, {
  tableName: 'collaborative_playlist_users',
  timestamps: true,
  indexes: [
    {
      unique: true,
      fields: ['playlistId', 'userId']
    }
  ]
});

module.exports = CollaborativePlaylistUser;
