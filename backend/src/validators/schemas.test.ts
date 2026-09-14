import { describe, it, expect } from 'vitest';
import {
  registerSchema,
  loginSchema,
  createVisitorSchema,
  updateVisitorSchema,
  createPaymentSchema,
  createBookingSchema,
  paginationSchema,
} from './schemas.js';

describe('schemas de validación', () => {
  describe('registerSchema', () => {
    it('acepta datos válidos', () => {
      const result = registerSchema.parse({
        email: 'usuario@test.com',
        password: 'Password123!',
        firstName: 'Ana',
        lastName: 'Lopez',
      });
      expect(result.email).toBe('usuario@test.com');
    });

    it('rechaza email inválido', () => {
      expect(() =>
        registerSchema.parse({
          email: 'no-email',
          password: 'Password123!',
          firstName: 'Ana',
          lastName: 'Lopez',
        })
      ).toThrow();
    });

    it('rechaza contraseña corta', () => {
      expect(() =>
        registerSchema.parse({
          email: 'a@b.com',
          password: '123',
          firstName: 'Ana',
          lastName: 'Lopez',
        })
      ).toThrow();
    });
  });

  describe('loginSchema', () => {
    it('acepta credenciales válidas', () => {
      const result = loginSchema.parse({ email: 'a@b.com', password: 'secret123' });
      expect(result.email).toBe('a@b.com');
    });

    it('rechaza sin email', () => {
      expect(() => loginSchema.parse({ password: 'secret123' })).toThrow();
    });
  });

  describe('createVisitorSchema', () => {
    it('requiere nombre y apellido', () => {
      expect(() => createVisitorSchema.parse({ firstName: 'Juan' })).toThrow();
    });

    it('acepta campos opcionales con string vacío en email', () => {
      const result = createVisitorSchema.parse({
        firstName: 'Maria',
        lastName: 'Perez',
        email: '',
      });
      expect(result.lastName).toBe('Perez');
    });
  });

  describe('updateVisitorSchema', () => {
    it('permite actualización parcial', () => {
      const result = updateVisitorSchema.parse({ phone: '555-0000' });
      expect(result.phone).toBe('555-0000');
    });

    it('rechaza email mal formado', () => {
      expect(() => updateVisitorSchema.parse({ email: 'invalido' })).toThrow();
    });
  });

  describe('createPaymentSchema', () => {
    it('requiere residentId y amount', () => {
      expect(() => createPaymentSchema.parse({ type: 'MAINTENANCE' })).toThrow();
    });

    it('acepta pago válido', () => {
      const result = createPaymentSchema.parse({
        residentId: '00000000-0000-0000-0000-000000000000',
        type: 'MAINTENANCE',
        amount: 1200,
        description: 'Mantenimiento de septiembre',
        dueDate: '2026-10-01T00:00:00.000Z',
      });
      expect(result.amount).toBe(1200);
    });
  });

  describe('createBookingSchema', () => {
    it('valida horarios', () => {
      expect(() =>
        createBookingSchema.parse({
          amenityId: 'x',
          unitId: 'y',
          startTime: 'no-date',
          endTime: 'no-date',
        })
      ).toThrow();
    });
  });

  describe('paginationSchema', () => {
    it('aplica defaults', () => {
      const result = paginationSchema.parse({});
      expect(result.page).toBe(1);
      expect(result.limit).toBe(20);
    });

    it('rechaza página inválida', () => {
      expect(() => paginationSchema.parse({ page: 0 })).toThrow();
    });
  });
});