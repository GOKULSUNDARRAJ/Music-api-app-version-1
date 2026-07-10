require('dotenv').config();
const { sequelize } = require('./models');

async function syncDb() {
  try {
    await sequelize.sync({ alter: true });
    console.log('Database synced successfully with alter: true');
  } catch (error) {
    console.error('Error syncing database:', error);
  } finally {
    process.exit(0);
  }
}

syncDb();
