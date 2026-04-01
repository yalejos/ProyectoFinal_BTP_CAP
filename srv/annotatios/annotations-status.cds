using {SalesOrder as service} from '../service';

annotate service.VH_Status with {
     @title: 'Status'
     code @Common: {
         Text : name,
         TextArrangement: #TextOnly
     }
} ;
