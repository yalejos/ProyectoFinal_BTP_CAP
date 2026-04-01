
const cds = require('@sap/cds');
const { SELECT, UPDATE } = require('@sap/cds/lib/ql/cds-ql');


const STATUS = {
    OPEN: 'O',
    CONFIRMED: 'C',
    SHIPPED: 'S',
    CANCELED: 'X'
};

module.exports = class SalesOrder extends cds.ApplicationService {

    async init() {
        const { SalesHeader, SalesItems } = this.entities;

        // --- Generación automática para el Header (orderID) ---

        this.before('NEW', SalesHeader.drafts, async (req) => {
            const lastOrder = await SELECT.one.from(SalesHeader).columns('orderID').orderBy('orderID desc');
            const lastDraft = await SELECT.one.from(SalesHeader.drafts).columns('orderID').orderBy('orderID desc');

            let maxID = 0;

            const extractNum = (obj) => obj?.orderID ? parseInt(obj.orderID.split('-')[1]) : 0;

            maxID = Math.max(extractNum(lastOrder), extractNum(lastDraft));

            if (maxID === 0) {
                maxID = 0; // Si no hay registros, empezamos desde 0
            }

            req.data.orderID = `SO-${(maxID + 1).toString().padStart(5, '0')}`;
            req.data.orderStatus_code = STATUS.OPEN;

            // --- Cálculo de la fecha (Hoy + 7 días) ---
            const deliveryDate = new Date();
            deliveryDate.setDate(deliveryDate.getDate() + 7);

            req.data.deliveryDate = deliveryDate.toISOString().split('T')[0];

        });

        // --- Generación automática para los Items (itemID) ---
        this.before('NEW', SalesItems.drafts, async (req) => {
            // 1. Intentamos obtener el ID del padre desde los datos o la URL del request
            const headerID = req.data.header_ID || req.params[0]?.ID;

            if (!headerID) {
                console.warn('No se pudo encontrar el ID de la cabecera');
                return;
            }

            // 2. Buscamos el último item SOLO para este header en la tabla de DRAFTS
            const lastItem = await SELECT.one.from(SalesItems.drafts)
                .columns('itemID')
                .where({ header_ID: headerID })
                .orderBy('itemID desc');

            let nextItemNum = 1;

            if (lastItem?.itemID) {
                // Extraemos el número: 'IT-0005' -> 5
                const lastNum = parseInt(lastItem.itemID.split('-')[1]) || 0;
                nextItemNum = lastNum + 1;
            }

            req.data.itemID = `IT-${nextItemNum.toString().padStart(4, '0')}`;

        });

        // --- Acciones de Cabecera ---

        this.on('confirmOrder', SalesHeader, async (req) => {
            const id = req.params[0].ID;
            const items = await SELECT.from(SalesItems).where({ header_ID: id });

            // Validación de items 
            for (const item of items) {
                if (!item.releaseDate) {
                    return req.error(400, `Product '${item.name}' must have a Release Date before the order can be confirmed.`, 'in/releaseDate');
                }
            }

            await UPDATE(SalesHeader).set({ orderStatus_code: STATUS.CONFIRMED }).where({ ID: id });
            return { message: `Order ${req.data.orderID || ''} has been successfully confirmed.` };
        });

        this.on('shipOrder', SalesHeader, async (req) => {
            const id = req.params[0].ID;
            const { delivery_date } = req.data;
            const today = new Date().toISOString().split('T')[0];

            const items = await SELECT.from(SalesItems).where({ header_ID: id });

            for (const item of items) {
                // Validation: Release Date exists
                if (!item.releaseDate) {
                    return req.error(400, `Cannot ship: Product '${item.name}' has no Release Date.`);
                }
                // Validation: Discontinued check (DiscontinuedDate <= Today)
                if (item.discontinuedDate && item.discontinuedDate <= today) {
                    return req.error(400, `Cannot ship: Product '${item.name}' was discontinued on ${item.discontinuedDate}.`);
                }
            }

            await UPDATE(SalesHeader).set({
                orderStatus_code: STATUS.SHIPPED,
                deliveryDate: delivery_date || today
            }).where({ ID: id });
            return { message: `Order shipped successfully. Delivery scheduled for ${delivery_date}.` };
        });

        this.on('cancelOrder', SalesHeader, async (req) => {
            const id = req.params[0].ID;
            const order = await SELECT.one.from(SalesHeader).columns('orderStatus_code').where({ ID: id });

            if (order.orderStatus_code === STATUS.SHIPPED) {
                return req.error(400, "Orders with status 'Shipped' cannot be canceled.");
            }

            await UPDATE(SalesHeader).set({ orderStatus_code: STATUS.CANCELED }).where({ ID: id });
            return { message: `Order has been successfully canceled.` };
        });

        // --- Acciones de Items ---

        this.on('getDefaultsForRelease', async (req) => {
            const today = new Date().toISOString().split('T')[0];
            return { release_date: today };
        });

        this.on('getDefaultsForDelivery', SalesHeader, async (req) => {
            const id = req.params[0].ID || req.params[0];

            const header = await SELECT.one.from(SalesHeader.drafts).where({ ID: id })
                || await SELECT.one.from(SalesHeader).where({ ID: id });

            const deliverydate = new Date(header.deliveryDate).toISOString().split('T')[0];

            return {
                delivery_date: deliverydate || new Date().toISOString().split('T')[0]
            };
        });

        this.on('releaseProduct', async (req) => {
            const id = req.params[req.params.length - 1].ID;
            const { release_date } = req.data; // Extraemos el parámetro del popup
            const today = new Date().toISOString().split('T')[0];
            const Entity = req.target.drafts || 'SalesOrder.SalesItems.drafts';

            if (!release_date) {
                return req.error(400, "A valid Release Date must be provided.", "in/release_date");
            }

            if (release_date < today) {
                return req.error(400, "Release Date cannot be in the past.", "in/release_date");
            }

            await UPDATE(Entity)
                .set({ releaseDate: release_date })
                .where({ ID: id });

           return SELECT.one.from(req.target.drafts).where({ ID: id });
        });

        this.on('discontinueProduct', async (req) => {
            const id = req.params[1].ID;
            const item = await SELECT.one.from(SalesItems).where({ ID: id });
            const today = new Date().toISOString().split('T')[0];

            if (!item.releaseDate) {
                return req.error(400, "A product cannot be discontinued if it hasn't been released yet.");
            }

            if (item.discontinuedDate && item.discontinuedDate < item.releaseDate) {
                return req.error(400, "Discontinued date cannot be earlier than the release date.");
            }

            await UPDATE(SalesItems.drafts).set({
                discontinuedDate: today,
                price: 0 
            })
                .where({ ID: id });
            return { message: `Product has been successfully marked as discontinued.` };
        });

        // --- Validaciones Generales (validateMandatoryFields / validatePrice) ---

        this.before(['CREATE', 'UPDATE'], SalesHeader, async (req) => {
            if (req.data.email === '' || req.data.email === null) {
                req.error(400, "Email is a mandatory field.", "in/email");
            }
        });

        this.before(['CREATE', 'UPDATE'], SalesItems, async (req) => {
            if (req.data.price <= 0) {
                req.error(400, `Invalid price for product '${req.data.name || 'Item'}'. Price must be greater than zero.`, "in/price");
            }
        });

        this.after('discontinueProduct', SalesItems, async (data, req) => {
            const headerID = req.params[0].ID || (await SELECT.one.from(SalesItems).columns('header_ID').where({ ID: req.params[0].ID })).header_ID;
            await this._updateTotal(headerID);
        });

        // Recalcular el total después de cualquier cambio en los ítems (Drafts)
        this.after(['CREATE', 'UPDATE', 'DELETE'], SalesItems.drafts, async (data, req) => {
            const headerID = data.header_ID || (await SELECT.one.from(SalesItems.drafts).columns('header_ID').where({ ID: data.ID }))?.header_ID;

            if (headerID) {
                await this._updateTotal(headerID);
            }
        });

        this.after('READ', SalesItems.drafts, (each) => {
            each.hasReleaseDate = !!each.releaseDate;
        });

        this.after('READ', 'SalesItems', (items, req) => {
            const asArray = Array.isArray(items) ? items : [items];
            const status = items.header?.orderStatus_code;

            asArray.forEach(item => {
                if (status === 'S' || status === 'X') {
                    item.isLockedInDetail = true;
                } else {
                    item.isLockedInDetail = false;
                }
            });
        });
        this.after('READ', 'SalesHeader', (each) => {
            // Si el estado es 'S', bloqueamos
            const status = each.orderStatus_code;
            if (status === 'S' || status === 'X') {
                each.isLockedInDetail = true;
            } else {
                each.isLockedInDetail = false;
            }
        });

        return super.init();
    };

    async _updateTotal(headerID) {

        const { SalesHeader, SalesItems } = this.entities;
        const today = new Date().toISOString().split('T')[0];

        // Obtener solo los ítems válidos (con no descontinuados)
        const validItems = await SELECT.from(SalesItems.drafts)
            .where({ header_ID: headerID })
            .and(`discontinuedDate is null or discontinuedDate > '${today}'`);

        // Sumar el (precio * cantidad)
        const total = validItems.reduce((acc, item) => {
            const p = parseFloat(item.price) || 0;
            const q = parseFloat(item.quantity) || 0;
            return acc + (p * q);
        }, 0);

        // Actualizar la cabecera (incluyendo la tabla de drafts si existe)
        await UPDATE(SalesHeader).set({ totalAmount: total }).where({ ID: headerID });
        await UPDATE(SalesHeader.drafts).set({ totalAmount: total }).where({ ID: headerID });
    }
}