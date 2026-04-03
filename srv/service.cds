using {com.ya as entities} from '../db/schema';

service SalesOrder {


    type formDelivery {
        fdeliverydate : Date;
    }

    type formRelease {
        freleasedate : Date;
    }

    entity SalesHeader as
        projection on entities.SalesHeader {
            *,

            firstName || ' ' || lastName as fullName : String,
            toSalesItems                             : redirected to SalesItems

        }  order by
            orderID asc
        actions {
            //Acciones de cabecera con controles dinámicos de visibilidad y side effects
            @Common: {SideEffects: {
                $Type           : 'Common.SideEffectsType',
                SourceProperties: [orderStatus_code],
                TargetProperties: ['orderStatus_code'],
                TargetEntities  : [$self],
            }}
            action   confirmOrder();

            function getDefaultsForDelivery() returns {
                delivery_date : Date
            };

            @Common: {SideEffects: {
                $Type           : 'Common.SideEffectsType',
                TriggerAction : 'shipOrder',
                SourceProperties: [orderStatus_code],
                TargetProperties: ['orderStatus_code', 'isLockedInDetail'],
                TargetEntities  : [$self]
            }}

            @(Common.DefaultValuesFunction: 'getDefaultsForDelivery')
            action   shipOrder(delivery_date: formDelivery:fdeliverydate);

            @Common: {SideEffects: {
                $Type           : 'Common.SideEffectsType',
                TriggerAction : 'cancelOrder',
                SourceProperties: [orderStatus_code],
                TargetProperties: ['orderStatus_code', 'isLockedInDetail'],
                TargetEntities  : [$self]                
            }}
            action   cancelOrder();
        };

    entity SalesItems  as
        projection on entities.SalesItems {
            *,
            header : redirected to SalesHeader
        }
        order by
            itemID asc
        actions {
            // Acciones para cada ítem

            action getDefaultsForRelease() returns {
                release_date : Date
            };

            @Common.SideEffects #OnDiscontinue: {
                SourceProperties: [releaseDate],
                TargetProperties: ['releaseDate'],
                TargetEntities  : [$self]
            }

            @(Common.DefaultValuesFunction: 'getDefaultsForRelease')
            action releaseProduct(release_date: formRelease:freleasedate);

        
            @Common.SideEffects #OnDiscontinue: {
                SourceProperties: [discontinuedDate],
                TargetProperties: [
                    'discontinuedDate',
                    'header/totalAmount'
                ],
                TargetEntities  : [$self]
            }

            action discontinueProduct();
        };

    @readonly
    entity VH_Status   as projection on entities.Status;


}
