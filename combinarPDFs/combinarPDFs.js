import { LightningElement, api, track } from 'lwc';
import pdflib                           from "@salesforce/resourceUrl/pdflib";
import { loadScript }                   from "lightning/platformResourceLoader";
import obtainDocument                   from '@salesforce/apex/UTILS_ReturnURLAsPDF.getPdfFileAsBase64String';
import obtainDocumentPDF                from '@salesforce/apex/UTILS_ReturnURLAsPDF.getPdfFileAsBase64StringFromPDF';
import guardarDocumento                 from '@salesforce/apex/UTILS_ReturnURLAsPDF.guardarDocumento';

export default class CombinarPDFs extends LightningElement {

    @api ContentVersionID_Initial;
    @api VisualforcePageCentral;
    @api contentVersionId;
    @api nombreDocumentoResultante;

    page1template_arraybuffer;
    page2template_arraybuffer;
    page3template_arraybuffer;
    finaltemplate_arraybuffer;
    recordID;

    @track showMergedDocument = false;

    async renderedCallback() {
        if (this.librariesLoaded) return;
        this.librariesLoaded = true;
        loadScript(this, pdflib)
            .then(async () => {
                console.log("#Succes loading PDFLIB");
                this.doTheMagic();
            })
            .catch(error => {
                console.log("#Failure loading PDFLIB----> ", error);
            });    

    }

    connectedCallback() {
        console.log('ConnectedCallback now');
    }

    async doTheMagic() {
        this.page1template_arraybuffer = await this.loadDocumentPDF(this.ContentVersionID_Initial);
        //this.page2template_arraybuffer = await this.loadDocumentPDF(this.VisualforcePageCentral);
        
        //Carga desde VFPç
        console.log("CONTENTVERSION CENTRAL-->" + this.VisualforcePageCentral);
        this.page2template_arraybuffer = await this.loadDocument("/apex/" + this.VisualforcePageCentral);

        await this.generarDocus();

        this.recordID=this.VisualforcePageCentral.split('=')[1];
        console.log("RECORD ID-->" + this.recordID);

        this.contentVersionId = await guardarDocumento( { fileBase64: this.finaltemplate_arraybuffer, fileName: this.nombreDocumentoResultante, fileExtension: "pdf",recordID: this.recordID } );
        console.log("guardarDocumento output: " + this.contentVersionId);
        // Opcion de descarga directa 
        // this.iFrameURL = '/sfc/servlet.shepherd/document/download/' + contentVersionId;
        this.iFrameURL = '/apex/previewContentDocumentFile?id=' + this.contentVersionId;
        this.showMergedDocument = true;
    }

    async loadDocument(inputURL){
        console.log("#URL ->" + inputURL);
        return obtainDocument({ url : inputURL});
    }

    async loadDocumentPDF(idContenido){
        return obtainDocumentPDF({idContentVersion :idContenido});
    }

    async generarDocus(){
        console.log("generarDocus------" + "init");

        const mergedPdf = await PDFLib.PDFDocument.create();

        // const pdfA = await pdflib.PDFDocument.load(fs.readFileSync('a.pdf'));
        const pdfA = await PDFLib.PDFDocument.load(this.page1template_arraybuffer);
        // const pdfB = await pdflib.PDFDocument.load(fs.readFileSync('b.pdf'));
        const pdfB = await PDFLib.PDFDocument.load(this.page2template_arraybuffer);
        
        const copiedPagesA = await mergedPdf.copyPages(pdfA, pdfA.getPageIndices());
        copiedPagesA.forEach((page) => mergedPdf.addPage(page));

        const copiedPagesB = await mergedPdf.copyPages(pdfB, pdfB.getPageIndices());
        copiedPagesB.forEach((page) => mergedPdf.addPage(page));

    
        const mergedPdfFile = await mergedPdf.save();
        // console.log("mergedPdfFile-------" + mergedPdfFile);
        const mergedPdfFileBase64 = await mergedPdf.saveAsBase64();
        // console.log("mergedPdfFileBase64-------" + mergedPdfFileBase64);
        this.finaltemplate_arraybuffer = mergedPdfFileBase64;
    }

}