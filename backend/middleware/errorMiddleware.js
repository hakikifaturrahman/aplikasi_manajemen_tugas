/**
 * Middleware Global Express untuk menangani error/exception yang tidak tertangkap di controller
 */
const errorHandler = (err, req, res, next) => {
  // Mencetak stack trace error ke console server
  console.error('Express Error Handler:', err.stack || err.message);

  // Jika response code masih 200, ubah ke 500 (Internal Server Error)
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  
  // Mengirimkan response JSON seragam berisi pesan kesalahan ke client
  res.status(statusCode).json({
    success: false,
    message: err.message || 'Internal Server Error'
  });
};

module.exports = { errorHandler };
