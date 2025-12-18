const sanitizeFilename = (filename) => {
  return filename.replace(/[^a-z0-9]/gi, '_');
};

export default sanitizeFilename;
