using {SalesOrder as service} from '../service';
using from './annotations-items';

annotate service.SalesHeader with @odata.draft.enabled;

annotate service.SalesHeader with {
    image        @title: 'Image'; 
    orderID      @title: 'Order ID'  @Core.Computed                    @Common.FieldControl   : #ReadOnly;
    fullName     @Core.Computed;
    firstName    @title: 'First Name';
    lastName     @title: 'Last Name';
    email        @title: 'Email';
    country      @title: 'Country'   @Common.Text  : country.name      @Common.TextArrangement: #TextOnly;
    deliveryDate @title: 'Delivery Date';

    orderStatus  @title: 'Status'    @Common.Text  : orderStatus.name  @Common.TextArrangement: #TextOnly;
    totalAmount  @title: 'Total Amount' @Core.Computed
};


annotate service.SalesHeader with @(

    //Filters
    UI.SelectionFields    : [
        orderID,
        country_code,
        orderStatus_code
    ],

    // Configuración del List Report (Tabla principal)
    UI.LineItem           : [
        {
            $Type: 'UI.DataField',
            Value: image,
            @UI.Importance: #High
        },
        {
            $Type             : 'UI.DataField',
            Value             : orderID,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '08rem'
            }
        },

        {
            $Type             : 'UI.DataField',
            Value             : firstName,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '10rem'
            }
        },
        {
            $Type             : 'UI.DataField',
            Value             : lastName,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '10rem'
            }
        },
        {
            $Type             : 'UI.DataField',
            Value             : email,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '10rem'
            }
        },
        {
            $Type             : 'UI.DataField',
            Value             : country_code,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '10rem'
            }
        },
        {
            $Type             : 'UI.DataField',
            Value             : orderStatus_code,
            Criticality       : orderStatus.criticality,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '7rem'
            }
        },
        {
            $Type             : 'UI.DataField',
            Value             : deliveryDate,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '12rem'
            }

        },
        {
            $Type             : 'UI.DataField',
            Value             : totalAmount,
            @HTML5.CssDefaults: {
                $Type: 'HTML5.CssDefaultsType',
                width: '10rem'
            }

        },
        {
            $Type             : 'UI.DataFieldForAction',
            Action            : 'service.confirmOrder',
            Label             : 'Confirm Order',
            InvocationGrouping: #ChangeSet
        },
        {
            $Type             : 'UI.DataFieldForAction',
            Action            : 'service.shipOrder',
            Label             : 'Ship Order',
            InvocationGrouping: #ChangeSet
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'service.cancelOrder',
            Label : 'Cancel Order'
        //Inline : true // Esto lo pone como un botón dentro de la fila
        }
    ],
    // Configuración del Object Page (Detalle)
    UI.HeaderInfo         : {
        TypeName      : 'Sales Order',
        TypeNamePlural: 'Sales Orders',
        Title         : {Value: orderID},
        Description   : {Value: fullName},
        ImageUrl      : image
    },

     UI.DataPoint #TotalAmount: {
        Value: totalAmount,
        Title: 'Total Amount',
        Criticality: #Positive,
        NumberFormat: { NumberOfFractionalDigits: 2 }
    },
    UI.HeaderFacets: [
        {
            $Type: 'UI.ReferenceFacet',
            Target: '@UI.DataPoint#TotalAmount'
        }
    ],

    UI.Facets             : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'General Information',
            Target: '@UI.FieldGroup#General'
        },
       
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Sales Items',
            Target: 'toSalesItems/@UI.LineItem'
        }
    ],
    UI.FieldGroup #Image : {
        Data : [
            {Value : image, Label : 'Imagen'}
        ]
    },
    UI.FieldGroup #General: {Data: [
        {
            $Type: 'UI.DataField',
            Value: firstName
        },
        {
            $Type: 'UI.DataField',
            Value: lastName
        },
        {
            $Type: 'UI.DataField',
            Value: email
        },
        {
            $Type: 'UI.DataField',
            Value: country_code
        },
        {
            $Type: 'UI.DataField',
            Value: deliveryDate
        },
        {
            $Type: 'UI.DataField',
            Value: image
        },
        {
            $Type      : 'UI.DataField',
            Value      : orderStatus_code,
            Criticality: orderStatus.criticality
        }
    ]},
    //Actions Object Page
    UI.Identification     : [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'service.confirmOrder',
            Label : 'Confirm Order'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'service.shipOrder',
            Label : 'Ship Order'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'service.cancelOrder',
            Label : 'Cancel Order'
        }
    ],
   

      Common.SideEffects #StatusChanged : {
        SourceProperties : [ orderStatus_code ],
        TargetProperties : [ orderStatus_code, deliveryDate ],
        TargetEntities: [ '$self' ]
    },
   

      
);

//Controlar visibilidad
annotate service.SalesHeader with actions {
    @Core.OperationAvailable: { $edmJson: { $And: [
        { $Eq: [{ $Path: 'orderStatus_code' }, 'O'] }, 
        { $Eq: [{ $Path: 'IsActiveEntity' }, true] }
    ]}}
    confirmOrder;

    @Core.OperationAvailable: {$edmJson: {$Eq: [{$Path: 'orderStatus_code'}, 'C']}}
    shipOrder;

   @Core.OperationAvailable: { $edmJson: { $And: [
        { $Ne: [{ $Path: 'orderStatus_code' }, 'S'] },
        { $Ne: [{ $Path: 'orderStatus_code' }, 'X'] },
        { $Eq: [{ $Path: 'IsActiveEntity' }, true] }
    ]}}
    cancelOrder;
    
};

annotate service.SalesHeader with @(
    UI.UpdateHidden : isLockedInDetail,
    Capabilities.DeleteRestrictions : {
        $Type      : 'Capabilities.DeleteRestrictionsType',
        Deletable  : {$edmJson: {$Ne: [{$Path: 'orderStatus_code'}, 'S']}}
    }
);




