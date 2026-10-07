import { Response } from 'express';

class ResponseHandler {
  success(res: Response, data: any, message: string = 'Success', statusCode: number = 200) {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
    });
  }

  error(res: Response, message: string = 'Error occurred', statusCode: number = 500, errors?: any) {
    return res.status(statusCode).json({
      success: false,
      message,
      ...(errors && { errors }),
    });
  }

  created(res: Response, data: any, message: string = 'Created successfully') {
    return this.success(res, data, message, 201);
  }

  notFound(res: Response, message: string = 'Resource not found') {
    return this.error(res, message, 404);
  }

  unauthorized(res: Response, message: string = 'Unauthorized access') {
    return this.error(res, message, 401);
  }

  forbidden(res: Response, message: string = 'Forbidden') {
    return this.error(res, message, 403);
  }

  badRequest(res: Response, message: string = 'Bad request', errors?: any) {
    return this.error(res, message, 400, errors);
  }
}

export default new ResponseHandler();
