/// Business Capabilities for Hard Isolation
///
/// This file defines granual business capabilities and maps them
/// to specific BusinessTypes. This serves as the "Permission Matrix"
/// for the application.
enum BusinessCapability {
  // ==============================================================================
  // 1. Product / Item Management
  // ==============================================================================
  useProductAdd,
  useProductName,
  useProductSalePrice,
  useProductStockQty,
  useProductUnit,
  useProductTax,
  useProductCategory,

  // ==============================================================================
  // 2. Inventory Management
  // ==============================================================================
  useInventoryList,
  useVisibleStock,
  useDeadStock,
  useInventorySearch,
  useInventoryExport,

  // ==============================================================================
  // 3. Invoice Management
  // ==============================================================================
  useInvoiceList,
  useInvoiceSearch,
  useInvoiceCreate,
  useSalesReturn,
  useProformaInvoice,
  useDispatchNote,

  // ==============================================================================
  // 4. Alerts & Business Health
  // ==============================================================================
  useLowStockAlert,
  useGeneralAlerts,
  useDailySnapshot,
  useRevenueOverview,

  // ==============================================================================
  // 5. Purchase & Stock Flow
  // ==============================================================================
  usePurchaseOrder,
  useStockEntry,
  useStockReversal,
  useSupplierBill,
  usePurchaseRegister,

  // ==============================================================================
  // LEGACY / SPECIALIZED CAPABILITIES (Retained for backward compat)
  // ==============================================================================
  // Prescription / Medical
  usePrescription,
  useDoctorLinking,
  usePatientRegistry,
  useDrugSchedule,
  useSaltSearch, // New: Pharmacy specific
  // UI / Input Methods
  useBarcodeScanner,
  useScanOCR,
  useVoiceInput, // Future ready
  // Inventory / Stock (Legacy aliases or specific behaviors)
  useBatchExpiry,
  useStockManagement, // Alias for useStockEntry + useVisibleStock
  useLowStockAlerts, // Alias for useLowStockAlert
  useMultiUnit, // Box/Pcs handling (Wholesale)
  useNegativeStock, // Allow selling without stock (optional)
  // Hardware / Dimensions
  useDimensions, // Hardware (Sq.ft/Mtr)
  useLooseQuantities,

  // Clothing / Variants
  useVariants, // Clothing (Size/Color)
  useTailoringNotes,

  // Electronics / Serial
  useIMEI, // Electronics
  useWarranty, // Electronics
  useBuyback, // Mobile Shop
  useExchange,

  // Restaurant
  useKOT,
  useTableManagement,
  useWaiterLinking,
  useKitchenDisplay,

  // Petrol Pump
  useFuelManagement,
  usePumpReadings,
  useShiftManagement,
  useVehicleDetails,
  useTankerEntry,

  // Services
  useJobSheets,
  useRepairStatus,
  useServiceStatus,
  useLaborCharges,

  // Broker / Mandi
  useCommission,
  useCrateManagement,
  useFarmerLinking,
  useDailyRates,

  // Wholesale / B2B
  useCreditManagement,
  useTransportDetails, // Delivery Challan/Vehicle No
  useCreditLimit,

  // Clinical / Medical Practice
  useAppointments,
  useConsultationBilling,
}

/// Registry that maps Business Types to their allowed Capabilities
///
/// RULE: Hard Isolation. If a capability is not listed here,
/// it is STRICTLY FORBIDDEN for that business type.
final Map<String, Set<BusinessCapability>> businessCapabilityRegistry = {
  'grocery': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,
    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useDeadStock,
    BusinessCapability.useInventorySearch,
    // Export CSV: ⚠️ (Optional/Limited) - Excluding for now or add if "Limited" means yes
    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    // Returns: ⚠️
    // Proforma: ❌
    // Dispatch: ❌
    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    BusinessCapability.useGeneralAlerts,
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,
    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    // Reversal: ⚠️
    BusinessCapability.useSupplierBill,
    // Purchase Register: ⚠️

    // Legacy / Extras
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useScanOCR,
    BusinessCapability.useStockManagement,
    BusinessCapability.useLowStockAlerts,
    BusinessCapability.useBatchExpiry,
    BusinessCapability.useVoiceInput,
  },
  'pharmacy': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,
    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useDeadStock,
    BusinessCapability.useInventorySearch,
    // Export CSV: ⚠️
    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    BusinessCapability.useSalesReturn,
    // Proforma: ⚠️
    // Dispatch: ⚠️
    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    BusinessCapability.useGeneralAlerts,
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,
    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    BusinessCapability.useStockReversal,
    BusinessCapability.useSupplierBill,
    BusinessCapability
        .usePurchaseRegister, // ⚠️ -> Included based on 'Optional' logic or check
    // Specialized
    BusinessCapability.usePrescription,
    BusinessCapability.useDoctorLinking,
    BusinessCapability.usePatientRegistry,
    BusinessCapability.useDrugSchedule,
    BusinessCapability.useSaltSearch,
    BusinessCapability.useBatchExpiry,
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useScanOCR,
    BusinessCapability.useStockManagement,
    BusinessCapability.useLowStockAlerts,
  },
  'restaurant': {
    // 1. Product
    // Add Item: ⚠️ (Limited)
    // Item Name: ⚠️
    // Sale Price: ⚠️
    // Stock Qty: ⚠️
    // Unit: ⚠️
    // Tax Select: ⚠️
    // Category: ⚠️
    // NOTE: Even if limited, we enable the base capability, logic handles limits
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory
    // List: ⚠️
    // Stock: ⚠️
    // Dead Stock: ⚠️ (Warining/Optional) -> Checklist says 'Limited' or 'Optional', enabling for now
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useDeadStock,
    BusinessCapability.useInventorySearch,
    // Export: ❌

    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    // Returns: ⚠️
    // Proforma: ❌
    // Dispatch: ❌

    // 4. Alerts
    BusinessCapability.useLowStockAlert, // List says ✅
    BusinessCapability.useGeneralAlerts,
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    // Reversal: ⚠️
    BusinessCapability.useSupplierBill,
    // Register: ⚠️

    // Specialized
    BusinessCapability.useKOT,
    BusinessCapability.useTableManagement,
    BusinessCapability.useWaiterLinking,
    BusinessCapability.useKitchenDisplay,
  },
  'clothing': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    // Dead Stock: ⚠️
    BusinessCapability.useInventorySearch,
    // Export: ⚠️

    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    // Returns: ⚠️
    // Proforma: ⚠️
    // Dispatch: ⚠️

    // 4. Alerts
    // Low Stock Alert: ⚠️
    // Alerts: ⚠️
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    // Reversal: ⚠️
    BusinessCapability.useSupplierBill,
    // Register: ⚠️

    // Specialized
    BusinessCapability.useVariants,
    BusinessCapability.useTailoringNotes,
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useScanOCR,
    BusinessCapability.useStockManagement,
  },
  'electronics': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    // Dead Stock: ⚠️
    BusinessCapability.useInventorySearch,
    // Export: ⚠️

    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    // Returns: ⚠️
    // Proforma: ⚠️
    // Dispatch: ⚠️

    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    // Alerts: ⚠️
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    // Reversal: ⚠️
    BusinessCapability.useSupplierBill,
    // Register: ⚠️

    // Specialized
    BusinessCapability.useIMEI,
    BusinessCapability.useWarranty,
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useScanOCR,
    BusinessCapability.useStockManagement,
  },
  'mobileShop': {
    // Checkbox says same as Electronics mostly
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory - Same as Electronics
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useInventorySearch,

    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,

    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    BusinessCapability.useSupplierBill,

    // Specialized
    BusinessCapability.useIMEI,
    BusinessCapability.useWarranty,
    BusinessCapability.useBuyback,
    BusinessCapability.useExchange,
    BusinessCapability.useJobSheets, // For repairs
    BusinessCapability.useRepairStatus,
    BusinessCapability.useStockManagement,
    BusinessCapability.useBarcodeScanner,
  },
  'computerShop': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useInventorySearch,

    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,

    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    BusinessCapability.useSupplierBill,

    // Specialized
    BusinessCapability.useIMEI,
    BusinessCapability.useWarranty,
    BusinessCapability.useJobSheets, // Custom builds/Repairs
    BusinessCapability.useRepairStatus,
    BusinessCapability.useStockManagement,
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useMultiUnit, // Parts
  },
  'hardware': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useInventorySearch,
    // Export: ⚠️

    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    // Returns: ⚠️
    // Proforma: ⚠️
    // Dispatch: ⚠️

    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    // Alerts: ⚠️
    BusinessCapability.useDailySnapshot, // ⚠️
    BusinessCapability.useRevenueOverview, // ⚠️
    // 5. Purchase
    BusinessCapability
        .usePurchaseOrder, // ❌ (Checklist says NO for Purchase Orders for Hardware? Wait, Checklist says ✅ for Purchase Orders for Hardware)
    // Checking Checklist: Hardware -> Purchase Orders ✅
    BusinessCapability.useStockEntry,
    // Reversal: ⚠️
    BusinessCapability.useSupplierBill,
    // Register: ⚠️

    // Specialized
    BusinessCapability.useDimensions,
    BusinessCapability.useLooseQuantities,
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useStockManagement,
    BusinessCapability.useTransportDetails,
  },
  'service': {
    // 1. Product (Service has ❌ for most item management in checklist?? No, Checklist says:
    // Service: Add Item ❌, Item Name ❌... Wait.
    // Checklist: Service -> Add Item ❌.
    // This implies Service business doesn't add "Items" but "Services" or "Jobs".
    // Keeping STRICT enabled only for what's checked.
    // However, they likely need SOME way to define services.
    // Checklist:
    // Add Item: ❌
    // Item Name: ❌
    // Sale Price: ❌
    // Stock Qty: ❌
    // Unit: ❌
    // Tax Select: ❌
    // Category: ❌
    // 2. Inventory
    // Inventory List: ❌
    // Available Stock: ❌
    // Dead Stock: ❌
    // Search: ❌
    // Export CSV: ❌
    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    // Returns: ❌
    // Proforma: ⚠️
    // Dispatch: ❌
    // 4. Alerts
    // Low Stock: ❌
    // Alerts: ⚠️
    // Daily Snapshot: ⚠️
    // Revenue: ⚠️
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,
    // 5. Purchase
    // Purchase Orders: ❌
    // Stock Entry: ❌
    // Reversal: ❌
    // Supplier Bills: ❌
    // Purchase Register: ❌

    // Specialized
    BusinessCapability.useJobSheets,
    BusinessCapability.useServiceStatus,
    BusinessCapability.useLaborCharges,
    BusinessCapability.useAppointments,
  },
  'wholesale': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useDeadStock,
    BusinessCapability.useInventorySearch,
    BusinessCapability.useInventoryExport, // ✅
    // 3. Invoice
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,
    BusinessCapability.useSalesReturn,
    BusinessCapability.useProformaInvoice, // ✅
    BusinessCapability.useDispatchNote, // ✅
    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    BusinessCapability.useGeneralAlerts,
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    BusinessCapability.useStockReversal,
    BusinessCapability.useSupplierBill,
    BusinessCapability.usePurchaseRegister,

    // Specialized
    BusinessCapability.useStockManagement,
    BusinessCapability.useMultiUnit,
    BusinessCapability.useCreditManagement,
    BusinessCapability.useCreditLimit,
    BusinessCapability.useTransportDetails,
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useBatchExpiry,
  },
  'petrolPump': {
    // 1. Product
    // Add Item: ⚠️
    // Item Name: ⚠️
    // Sale Price: ⚠️
    // Stock Qty: ⚠️
    // Unit: ⚠️
    // Tax Select: ⚠️
    // Category: ⚠️
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    BusinessCapability.useProductTax,
    BusinessCapability.useProductCategory,

    // 2. Inventory
    // Inventory List: ⚠️
    // Available Stock: ⚠️
    // Dead Stock: ❌
    // Search: ⚠️
    // Export: ❌
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    BusinessCapability.useInventorySearch,

    // 3. Invoice
    BusinessCapability.useInvoiceList,
    // Search: ⚠️
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate, // ✅ in logic, though checklist says ✅
    // Returns: ⚠️
    // Proforma: ❌
    // Dispatch: ❌

    // 4. Alerts
    // Low Stock: ⚠️
    // Alerts: ⚠️
    // Snapshot: ⚠️
    // Revenue: ⚠️
    BusinessCapability.useLowStockAlert,
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    // PO: ⚠️
    // Entry: ⚠️
    // Reversal: ❌
    // Bills: ⚠️
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    BusinessCapability.useSupplierBill,

    // Specialized
    BusinessCapability.useFuelManagement,
    BusinessCapability.usePumpReadings,
    BusinessCapability.useShiftManagement,
    BusinessCapability.useVehicleDetails,
    BusinessCapability.useTankerEntry,
    BusinessCapability.useStockManagement, // Fuel stock
  },
  'vegetablesBroker': {
    // 1. Product
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useProductSalePrice,
    BusinessCapability.useProductStockQty,
    BusinessCapability.useProductUnit,
    // Tax: ⚠️ (Mandi often no tax)
    // Category: ✅
    BusinessCapability.useProductCategory,

    // 2. Inventory
    BusinessCapability.useInventoryList,
    BusinessCapability.useVisibleStock,
    // Dead Stock: ⚠️
    BusinessCapability.useInventorySearch,
    // Export: ⚠️

    // 3. Invoice
    // Invoice List: ⚠️
    // Search: ⚠️
    // Create: ⚠️
    // Returns: ⚠️
    // Proforma: ⚠️
    // Dispatch: ⚠️
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,

    // 4. Alerts
    BusinessCapability.useLowStockAlert,
    // Alerts: ⚠️
    // Snapshot: ⚠️
    // Revenue: ⚠️
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    BusinessCapability.usePurchaseOrder,
    BusinessCapability.useStockEntry,
    // Reversal: ⚠️
    BusinessCapability.useSupplierBill, // ⚠️
    // Register: ⚠️

    // Specialized
    BusinessCapability.useCommission,
    BusinessCapability.useCrateManagement,
    BusinessCapability.useFarmerLinking,
    BusinessCapability.useDailyRates,
    BusinessCapability.useCreditManagement,
  },
  'clinic': {
    // 1. Product
    // Add Item: ❌ (Doctors don't add items usually, they add Services/Meds in a different flow)
    // Item Name: ❌
    // ... All ❌ for Product ??
    // Checklist: Clinic -> ❌ for all Product features.
    // 2. Inventory
    // All ❌
    // 3. Invoice
    // Invoice List: ⚠️
    // Search: ⚠️
    // Create: ⚠️
    // Returns: ❌
    // Proforma: ❌
    // Dispatch: ❌
    BusinessCapability.useInvoiceList,
    BusinessCapability.useInvoiceSearch,
    BusinessCapability.useInvoiceCreate,

    // 4. Alerts
    // Low Stock: ❌
    // Alerts: ⚠️
    // Snapshot: ⚠️
    // Revenue: ⚠️
    BusinessCapability.useDailySnapshot,
    BusinessCapability.useRevenueOverview,

    // 5. Purchase
    // All ❌

    // Specialized
    BusinessCapability.useAppointments,
    BusinessCapability.useConsultationBilling,
    BusinessCapability.usePatientRegistry,
    BusinessCapability.usePrescription,
    BusinessCapability.useDoctorLinking,
  },
  'other': {
    // Default safe features
    BusinessCapability.useProductAdd,
    BusinessCapability.useProductName,
    BusinessCapability.useStockManagement,
    BusinessCapability.useBarcodeScanner,
    BusinessCapability.useInvoiceCreate,
    BusinessCapability.useInvoiceList,
  },
};
