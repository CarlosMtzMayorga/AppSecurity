import { Request, Response, NextFunction } from 'express';

export const requestLogger = (req: Request, _res: Response, next: NextFunction): void => {
  const start = Date.now();
  
  const originalSend = _res.send;
  _res.send = function (body?: unknown): Response {
    const duration = Date.now() - start;
    const logData = {
      method: req.method,
      url: req.originalUrl,
      status: _res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.get('user-agent')?.substring(0, 100),
    };
    
    if (process.env.NODE_ENV === 'development') {
      console.log('📥', JSON.stringify(logData));
    }
    
    return originalSend.call(this, body);
  };
  
  next();
};