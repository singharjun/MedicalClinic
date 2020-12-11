import { LightningElement,api, wire, track } from 'lwc';
import getDoctors from "@salesforce/apex/MakeAppointmentController.getDoctors"; 
import getAppointmentPrice from "@salesforce/apex/MakeAppointmentController.getAppointmentPrice"; 
import getEvents from "@salesforce/apex/MakeAppointmentController.getEvents"; 
import bookAppointment from "@salesforce/apex/MakeAppointmentController.bookAppointment"; 
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import TYPE_FIELD from "@salesforce/schema/Account.Type";
import { NavigationMixin } from 'lightning/navigation';
const DELAY = 300;
const recordsPerPage = [5, 10, 15, 20];
const pageNumber = 1;
const showIt = "visibility:visible";
const hideIt = "visibility:hidden"; 
    
export default class MakeAppointment extends NavigationMixin(LightningElement) {
    @api recordId;
    @track specializationsList;
    @track selectedSpecialization = "--Select--";

    @track showTable = false; //Used to render table after we get the data from apex controller
    @track recordsToDisplay = []; //Records to be displayed on the page
    @track rowNumberOffset; //Row number
    @track sortedBy;
    @track sortedDirection = "desc";
    @track showSearchBox = false; //Show/hide search box; valid values are true/false
    @track showPagination; //Show/hide pagination; valid values are true/false
    @track pageSizeOptions = recordsPerPage; //Page size options; valid values are array of integers
    @track totalRecords; //Total no.of records; valid type is Integer
    @track records; //All records available in the data table; valid type is Array
    @track pageSize; //No.of records to be displayed per page
    @track totalPages; //Total no.of pages
    @track pageNumber = pageNumber; //Page number
    @track searchKey; //Search Input
    @track controlPagination = showIt;
    @track controlPrevious = hideIt; //Controls the visibility of Previous page button
    @track controlNext = showIt; //Controls the visibility of Next page button
    recordsToDisplay = []; //Records to be displayed on the page
    @track defaultNumber = "5";
    @track Slots = [];
    @track showSpinner = true;
    @track appointments=[];
    @track selectedEvent;
    @track selectedSpecializationPrice;
    @track doctorsWithPriceDetail;
    @track showCalendar = false;
    @track selectedDoctor;
    @track showPopUp;
    @track errorInFetchingEvents = false;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: "$objectInfo.data.defaultRecordTypeId",
        fieldApiName: TYPE_FIELD
      })
      typePickListValuesSet({ error, data }) {
        if (data) {
          this.specializationsList = [
            { label: "--Select--", value: "--Select--" },
            ...data.values
          ];
        } else {
          this.error = error;
        }
      }
      
   
    connectedCallback() {
        this.showPopUp = false;
        getDoctors({searchKey: this.selectedSpecialization})
        .then(result=>{
            this.records = result.doctorsList;
            this.totalRecords = result.doctorsList.length;
            this.recordsToDisplay = result.doctorsList;
            this.showTable = true;
            if (this.pageSizeOptions && this.pageSizeOptions.length > 0)
                this.pageSize = this.pageSizeOptions[0];
            else {
                this.pageSize = this.totalRecords;
                this.showPagination = false;
            }
            this.controlPagination =
                this.showPagination === false ? hideIt : showIt;
            this.setRecordsToDisplay();
            console.log('Here2');
            this.showSearchBox = true;
            this.showSpinner = false;

        })
        .catch(error=>{
            console.log('Error in getting doctors details ');
        })
    }
    /**
   * Used to implement the sorting feature on datatable
   */
  sortData(fieldName, sortDirection) {
    var data = JSON.parse(JSON.stringify(this.recordsToDisplay));
    //function to return the value stored in the field
    var key = a => a[fieldName];
    var reverse = sortDirection === "asc" ? 1 : -1;
    data.sort((a, b) => {
      let valueA = key(a) ? key(a).toLowerCase() : "";
      let valueB = key(b) ? key(b).toLowerCase() : "";
      return reverse * ((valueA > valueB) - (valueB > valueA));
    });

    //set sorted data to opportunities attribute
    this.recordsToDisplay = data;
  }
  handleRecordsPerPage(event) {
    this.pageSize = event.target.value;
    this.setRecordsToDisplay();
  }
  handlePageNumberChange(event) {
    if (event.keyCode === 13) {
      this.pageNumber = event.target.value;
      this.setRecordsToDisplay();
    }
  }
  previousPage() {
    this.pageNumber = this.pageNumber - 1;
    this.setRecordsToDisplay();
  }
  nextPage() {
    this.pageNumber = this.pageNumber + 1;
    this.setRecordsToDisplay();
  }
  setRecordsToDisplay() {
    this.recordsToDisplay = [];
    if (!this.pageSize) this.pageSize = this.totalRecords;
    this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
    this.setPaginationControls();
    for (
      let i = (this.pageNumber - 1) * this.pageSize;
      i < this.pageNumber * this.pageSize;
      i++
    ) {
      if (i === this.totalRecords) break;
      this.recordsToDisplay.push(this.records[i]);
    }
    //this.dispatchEvent(new CustomEvent('paginatorchange', {detail: this.recordsToDisplay})); //Send records to display on table to the parent component
    //this.recordsToDisplay = event.detail;
    if (this.recordsToDisplay[0] != null) {
      this.rowNumberOffset = this.recordsToDisplay[0].rowNumber - 1;
    } else {
      console.log("No cases found");
    }
  }
  setPaginationControls() {
    //Control Pre/Next buttons visibility by Total pages
    if (this.totalPages === 1) {
      this.controlPrevious = hideIt;
      this.controlNext = hideIt;
    } else if (this.totalPages > 1) {
      this.controlPrevious = showIt;
      this.controlNext = showIt;
    }
    //Control Pre/Next buttons visibility by Page number
    if (this.pageNumber <= 1) {
      this.pageNumber = 1;
      this.controlPrevious = hideIt;
    } else if (this.pageNumber >= this.totalPages) {
      this.pageNumber = this.totalPages;
      this.controlNext = hideIt;
    }
    //Control Pre/Next buttons visibility by Pagination visibility
    if (this.controlPagination === hideIt) {
      this.controlPrevious = hideIt;
      this.controlNext = hideIt;
    }
  }
  handleKeyChange(event) {
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    if (searchKey) {
      this.delayTimeout = setTimeout(() => {
        this.controlPagination = hideIt;
        this.setPaginationControls();

        this.searchKey = searchKey;
        //Use other field name here in place of 'Name' field if you want to search by other field
        //this.recordsToDisplay = this.records.filter(rec => rec.includes(searchKey));
        //Search with any column value (Updated as per the feedback)
        this.recordsToDisplay = this.records.filter(rec =>
          JSON.stringify(rec).includes(searchKey)
        );
        if (
          Array.isArray(this.recordsToDisplay) &&
          this.recordsToDisplay.length > 0
        )
          if (this.recordsToDisplay[0] != null) {
            //this.dispatchEvent(new CustomEvent('paginatorchange', {detail: this.recordsToDisplay})); //Send records to display on table to the parent component
            this.rowNumberOffset = this.recordsToDisplay[0].rowNumber - 1;
          } else {
            console.log("No record found");
          }
      }, DELAY);
    } else {
      this.controlPagination = showIt;
      this.setRecordsToDisplay();
    }
  }  

  getGoogleEvents(event){
      this.showSpinner = true;
      let selectedDateVar = event.target.value;
      getEvents({selectedDate: selectedDateVar, selectedDoctor: JSON.stringify(this.selectedDoctor)})
        .then(res=>{
          console.log('res>>>>',res);
          this.showSpinner = false;
          if(res == null){
            this.errorInFetchingEvents = true;
          }
          this.appointments =  res;
        })
        .catch(error=>{
          this.showSpinner = false;
        })
  }
      
  handleSpecializationChange(event){
    this.showSpinner = true;
    this.showCalendar = false;
    getAppointmentPrice({selectedSpecialization: event.target.value})
        .then(result=>{
              this.selectedSpecializationPrice = result.selectedPrice;
              this.records = result.doctorsList;
              this.totalRecords = result.doctorsList.length;
               this.recordsToDisplay = result.doctorsList;
               this.showSpinner = false;
               
        })
        .catch(error=>{
            console.log('Error in getting Price details ', error);
            this.showSpinner = false;
        })
  }
  selectDoctorHandler(event){
    this.showCalendar = false;
    var selectedItem = event.currentTarget; // Get the target object
    var index = selectedItem.dataset.item; // Get its value i.e. the index
    this.selectedDoctor = this.recordsToDisplay[index];
    let compSelect = this.template.querySelectorAll('.singleRadio');
    
    this.template.querySelectorAll('.singleRadio').forEach(rec =>{
      if(rec.name === index){
      }else{
        rec.checked = false;
      }
    })
    this.showCalendar = true;
  }
  selectEventTimeHandler(event){
    this.showSpinner = true;
    var selectedItem = event.currentTarget; // Get the target object
    var index = selectedItem.dataset.item; // Get its value i.e. the index
    this.selectedEvent = this.appointments[index];
    let compVar = this.template.querySelectorAll('.appointmentBtn');
    this.template.querySelectorAll('.appointmentBtn').forEach(rec =>{
      if(rec.name == index){
        rec.disabled = true;
      }else{
        rec.disabled = false;
      }
    })
    this.showSpinner = false;
  }
    bookAppointment(){
      this.showSpinner = true;
      bookAppointment({
              eventDetails: JSON.stringify(this.selectedEvent),
              selectedDoctor: JSON.stringify(this.selectedDoctor),
              selectedPatient: this.recordId 
            })
        .then(res=>{
          console.log('res>>>>',res);
          this.showSpinner = false;
          this.showPopUp = true;          
        })
        .catch(error=>{
          
        })
      
    }
    closeModal(){        
      // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Parent__c', // objectApiName is optional
                actionName: 'view'
            }
        });
    
    }
}