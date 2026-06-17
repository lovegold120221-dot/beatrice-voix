export interface FileExtractResult {
  success: boolean;
  textContent?: string;
  base64Content?: string;
  mimeType: string;
  fileName?: string;
  fileSize: number;
  error?: string;
}

const TEXT_MIMES = new Set([
  'text/plain', 'text/html', 'text/csv', 'text/markdown', 'text/xml',
  'application/json', 'application/xml', 'application/javascript',
  'application/typescript', 'application/yaml',
]);

const TEXT_EXTENSIONS = new Set([
  'txt', 'csv', 'json', 'md', 'html', 'htm', 'xml', 'yaml', 'yml',
  'log', 'env', 'cfg', 'ini', 'toml', 'css', 'js', 'ts', 'py', 'sh',
  'bat', 'ps1', 'sql', 'r', 'lua', 'pl', 'rb', 'php', 'java', 'c',
  'cpp', 'h', 'hpp', 'go', 'rs', 'swift', 'kt', 'gradle', 'properties',
]);

export function extractFileContent(buffer: Buffer, mimeType: string, fileName?: string): FileExtractResult {
  const mime = mimeType || 'application/octet-stream';
  const ext = fileName?.split('.').pop()?.toLowerCase();

  if (TEXT_MIMES.has(mime) || (ext && TEXT_EXTENSIONS.has(ext))) {
    const text = buffer.toString('utf-8');
    return { success: true, textContent: text, mimeType: mime, fileName, fileSize: buffer.length };
  }

  if (mime.startsWith('image/')) {
    const base64 = buffer.toString('base64');
    return { success: true, base64Content: `data:${mime};base64,${base64}`, mimeType: mime, fileName, fileSize: buffer.length };
  }

  if (mime === 'application/pdf' || ext === 'pdf') {
    const raw = buffer.toString('utf-8');
    const cleaned = raw.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, ' ').replace(/\s+/g, ' ').trim();
    if (cleaned.length > 50) {
      return { success: true, textContent: cleaned.substring(0, 100000), mimeType: mime, fileName, fileSize: buffer.length };
    }
    return {
      success: true,
      textContent: `[PDF document: ${fileName || 'unnamed'}, ${(buffer.length / 1024).toFixed(1)} KB — text extraction unavailable. The user can see this file in WhatsApp.]`,
      mimeType: mime, fileName, fileSize: buffer.length,
    };
  }

  if (mime.startsWith('audio/')) {
    return {
      success: true,
      textContent: `[Audio file: ${fileName || 'unnamed'}, ${(buffer.length / 1024).toFixed(1)} KB — audio transcription not available.]`,
      mimeType: mime, fileName, fileSize: buffer.length,
    };
  }

  if (mime.startsWith('video/')) {
    return {
      success: true,
      textContent: `[Video file: ${fileName || 'unnamed'}, ${(buffer.length / 1024).toFixed(1)} KB — video content extraction not available.]`,
      mimeType: mime, fileName, fileSize: buffer.length,
    };
  }

  return {
    success: true,
    textContent: `[File: ${fileName || 'unnamed'}, type: ${mime}, size: ${(buffer.length / 1024).toFixed(1)} KB — content extraction not available for this file type.]`,
    mimeType: mime, fileName, fileSize: buffer.length,
  };
}
