# Dead Code Report

This report identifies potentially unused code in the Signaux Faibles application.

## Summary

- **Controllers**: 1 unused controller
- **Helpers**: 3 empty or redundant helpers
- **JavaScript Controllers**: 1 unused controller
- **Test/Dev Code**: 1 test controller that may not be needed in production

---

## 1. Controllers

### ❌ CampaignsController (`app/controllers/campaigns_controller.rb`)

**Status**: **DEAD CODE**

**Details**:
- Controller exists with `index` and `show` actions
- **No routes defined** in `config/routes.rb`
- **No views** exist for campaigns
- Campaign model is used elsewhere (in `CompaniesController` and helpers), but the controller itself is not accessible

**Recommendation**: Delete the controller file unless campaigns functionality is planned for the future.

**Files to delete**:
- `app/controllers/campaigns_controller.rb`

---

## 2. Helpers

### ❌ CampaignsHelper (`app/helpers/campaigns_helper.rb`)

**Status**: **DEAD CODE**

**Details**:
- Empty module with no methods
- Not used anywhere in the codebase

**Recommendation**: Delete the helper file.

**Files to delete**:
- `app/helpers/campaigns_helper.rb`

---

### ❌ TrackingsHelper (`app/helpers/trackings_helper.rb`)

**Status**: **DEAD CODE**

**Details**:
- Empty module with no methods
- Not used anywhere in the codebase

**Recommendation**: Delete the helper file.

**Files to delete**:
- `app/helpers/trackings_helper.rb`

---

### ⚠️ UsersHelper (`app/helpers/users_helper.rb`)

**Status**: **REDUNDANT CODE**

**Details**:
- Contains `full_name(user)` method that duplicates `User#full_name` instance method
- The helper method is **never called** in views
- All views use `user.full_name` (the model method) instead of `full_name(user)` (the helper method)

**Recommendation**: Delete the `full_name` method from the helper, or delete the entire helper if it only contains this method.

**Files to modify/delete**:
- `app/helpers/users_helper.rb` - Remove `full_name` method or delete entire file if empty

---

## 3. JavaScript Controllers

### ❌ submit_on_change_controller.js (`app/javascript/controllers/submit_on_change_controller.js`)

**Status**: **DEAD CODE**

**Details**:
- JavaScript controller exists but is **never referenced** in any view
- No `data-controller="submit-on-change"` attributes found in the codebase
- Controller auto-submits a form when a select element changes

**Recommendation**: Delete the controller file unless it's planned for future use.

**Files to delete**:
- `app/javascript/controllers/submit_on_change_controller.js`

---

## 4. Test/Development Code

### ⚠️ ChartsController (`app/controllers/charts_controller.rb`)

**Status**: **POTENTIALLY DEAD CODE (Test/Dev Only)**

**Details**:
- Routes comment says: `# Routes pour les graphiques de test` (Routes for test charts)
- Contains test data (hardcoded arrays)
- View exists at `app/views/charts/index.html.erb` with test charts
- May be used for development/testing purposes

**Recommendation**: 
- If this is only for development/testing, consider removing it from production routes
- Or document it as a test/development tool
- If not needed, delete both controller and view

**Files to review/delete**:
- `app/controllers/charts_controller.rb`
- `app/views/charts/index.html.erb`
- Routes in `config/routes.rb` (lines 17-23)

---

## 5. Models (All Used)

All models appear to be in use:
- ✅ `Campaign` - Used in `CompaniesController` and `CompaniesHelper`
- ✅ `CampaignCompany` - Used in seeds and associations
- ✅ `CodefiRedirect` - Used extensively in views and controllers
- ✅ `CompanyList` - Used in seeds and associations
- ✅ `Network` - Used extensively throughout the app
- ✅ `NetworkMembership` - Used in associations
- ✅ `Entity` - Used in User model and views
- ✅ `SupportingService` - Used extensively in views and controllers

---

## 6. Services (All Used)

All services appear to be in use:
- ✅ OSF sync services are called via rake tasks
- ✅ API services are used in controllers
- ✅ Excel generation service is used for exports

---

## 7. JavaScript Controllers (Used)

The following JavaScript controllers are actively used:
- ✅ `auto_resize_controller.js` - Used in comments view
- ✅ `download_controller.js` - Used in establishment trackings table
- ✅ `filters_toggle_controller.js` - Used in filters view
- ✅ `orthogonal_chart_widget_controller.js` - Used in data widgets
- ✅ `segmented_control_widget_controller.js` - Used in data widgets
- ✅ `tracking_status_controller.js` - Used in edit view
- ✅ `view_toggle_controller.js` - Used in search forms

---

## Action Items

### High Priority (Definitely Dead Code)
1. Delete `app/controllers/campaigns_controller.rb`
2. Delete `app/helpers/campaigns_helper.rb`
3. Delete `app/helpers/trackings_helper.rb`
4. Delete `app/javascript/controllers/submit_on_change_controller.js`
5. Remove `full_name` method from `app/helpers/users_helper.rb` (or delete file if empty)

### Medium Priority (Review Needed)
1. Review `ChartsController` - determine if it's needed for production or only for testing
2. If test-only, remove from production routes or delete entirely

---

## Notes

- This analysis was performed by searching for usage patterns across the codebase
- Some code may be planned for future use - verify with the team before deletion
- Always run tests after removing code to ensure nothing breaks
- Consider using tools like `debride` or `fasterer` for more comprehensive dead code detection

